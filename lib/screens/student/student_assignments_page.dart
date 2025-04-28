import 'dart:io'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart'; 
import '../pdf_viewer_page.dart'; 
import '../../helpers/hive_helper.dart';
import '../../models/assignment.dart';



class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({Key? key}) : super(key: key);

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  String schoolDomain = '';
  String grade = '';
  String uid = '';
  String studentName = '';
  bool isLoading = true;

  Map<String, List<Assignment>> groupedAssignments = {};
  Map<String, Uint8List?> selectedFileBytes = {};
  Map<String, String> selectedFileName = {};
  Map<String, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final profileBox = Hive.box('profileBox');

    if (user == null) {
      final cached = profileBox.get('studentProfile');
      if (cached != null) {
        uid = cached['uid'];
        studentName = cached['fullName'];
        grade = cached['grade'];
        schoolDomain = cached['schoolDomain'];
        fetchAssignments();
      }
      return;
    }

    // online mode
    final studentId = user.uid;
    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('students')
          .doc(studentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        uid = studentId;
        schoolDomain = school.id;
        grade = data['grade'];
        studentName = data['fullName'];

        // offline mode
        await profileBox.put('studentProfile', {
          'uid': uid,
          'fullName': studentName,
          'grade': grade,
          'schoolDomain': schoolDomain,
        });

        fetchAssignments();
        break;
      }
    }
  }

  Future<void> openFile(String url) async {
    try {
      final filename = url.split('/').last.split('?').first; 

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';

      final file = File(filePath);

      if (await file.exists()) {
        await OpenFile.open(filePath);
        print('✅ Opened local file: $filePath');
      } else {
        print('⬇️ Downloading $url');
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          await OpenFile.open(filePath);
          print('✅ Downloaded and opened: $filePath');
        } else {
          throw Exception('Failed to download file');
        }
      }
    } catch (e) {
      print('❌ Error opening file: $e');
    }
  }
  Future<void> fetchAssignments() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('assignments')
          .orderBy('dueDate')
          .get();

      final Map<String, List<Assignment>> grouped = {};
      List<Assignment> allAssignments = [];

      for (var doc in snap.docs) {
        final submission = await doc.reference
            .collection('submissions')
            .doc(uid)
            .get();

        if (submission.exists) continue;

        final data = doc.data();
        final assignment = Assignment(
          id: doc.id,
          title: data['title'],
          subject: data['subject'],
          dueDate: (data['dueDate'] as Timestamp).toDate().toIso8601String(),
          fileUrl: data['fileUrl'],
          description: data['description'],
          type: data['type'],
          createdInAppText: data['createdInAppText'],
        );

        allAssignments.add(assignment);

        final subject = assignment.subject ?? 'Uncategorized';
        grouped.putIfAbsent(subject, () => []).add(assignment);
        textControllers[assignment.id] = TextEditingController();
      }

      await saveAssignmentsToHive(allAssignments);
      print('💾 Saved ${allAssignments.length} assignments to Hive');

      setState(() {
        groupedAssignments = grouped;
        isLoading = false;
      });
    } catch (e) {
      print("🔥 Firestore failed, loading from Hive instead: $e");

      final offlineAssignments = loadAssignmentsFromHive();
      print('📦 Loaded ${offlineAssignments.length} assignments from Hive');

      final Map<String, List<Assignment>> offlineGrouped = {};

      for (var assignment in offlineAssignments) {
        final subject = assignment.subject ?? 'Uncategorized';
        offlineGrouped.putIfAbsent(subject, () => []).add(assignment);
        textControllers[assignment.id] = TextEditingController();
      }

      setState(() {
        groupedAssignments = offlineGrouped;
        isLoading = false;
      });
    }
  }


  Future<void> pickFile(String assignmentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedFileBytes[assignmentId] = result.files.single.bytes!;
        selectedFileName[assignmentId] = result.files.single.name;
      });
    }
  }

  Future<void> submitAssignment(Assignment assignment) async {
    final assignmentId = assignment.id;
    final textAnswer = textControllers[assignmentId]?.text.trim() ?? "";
    final file = selectedFileBytes[assignmentId];
    final fileName = selectedFileName[assignmentId];

    if (textAnswer.isEmpty && file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a file or enter a text answer.")),
      );
      return;
    }

    try {
      String? fileUrl;
      if (file != null && fileName != null) {
        final ref = FirebaseStorage.instance
            .ref('assignment_submissions/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putData(file);
        fileUrl = await ref.getDownloadURL();
      }

      final submissionData = {
        'studentId': uid,
        'studentName': studentName,
        'textAnswer': textAnswer,
        'fileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(uid)
          .set(submissionData);

      setState(() {
        final subject = assignment.subject ?? 'Uncategorized';
        groupedAssignments[subject]?.removeWhere((doc) => doc.id == assignmentId);

        if (groupedAssignments[subject]?.isEmpty ?? false) {
          groupedAssignments.remove(subject);
        }

        textControllers.remove(assignmentId);
        selectedFileBytes.remove(assignmentId);
        selectedFileName.remove(assignmentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Assignment submitted!")),
      );
    } catch (e) {
      print('❌ Assignment submission failed, saving offline: $e');

      final pendingBox = await Hive.openBox('pendingSubmissions');

      await pendingBox.add({
        'type': 'assignment',
        'assignmentId': assignmentId,
        'schoolDomain': schoolDomain,
        'grade': grade,
        'uid': uid,
        'studentName': studentName,
        'textAnswer': textAnswer,
        'fileBytes': file,   
        'fileName': fileName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        final subject = assignment.subject ?? 'Uncategorized';
        groupedAssignments[subject]?.removeWhere((doc) => doc.id == assignmentId);

        if (groupedAssignments[subject]?.isEmpty ?? false) {
          groupedAssignments.remove(subject);
        }

        textControllers.remove(assignmentId);
        selectedFileBytes.remove(assignmentId);
        selectedFileName.remove(assignmentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Saved offline. Will auto-submit when online.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📘 My Assignments")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedAssignments.isEmpty
              ? Center(child: Text("No assignments available."))
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: groupedAssignments.entries.map((entry) {
                    final subject = entry.key;
                    final assignments = entry.value;
                    final subjectColor = Colors.primaries[subject.hashCode % Colors.primaries.length].shade100;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: subjectColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(subject, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...assignments.map((assignment) {
                          final id = assignment.id;
                          final title = assignment.title;
                          final description = assignment.description ?? '';
                          final inAppText = assignment.createdInAppText ?? '';
                          final fileUrl = assignment.fileUrl;
                          final type = assignment.type  ?? 'file';

                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (description.isNotEmpty) Text("📝 $description"),
                                  if (type == "in-app" && inAppText.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(inAppText),
                                    ),
                                  if (type == "file" && fileUrl != null)
                                    TextButton.icon(
                                      icon: Icon(Icons.picture_as_pdf),
                                      label: Text("Open File"),
                                      onPressed: () => openFile(fileUrl),
                                    ),
                                  SizedBox(height: 10),
                                  Text("✏️ Submit Answer"),
                                  TextField(
                                    controller: textControllers[id],
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: InputDecoration(border: OutlineInputBorder()),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => pickFile(id),
                                    icon: Icon(Icons.upload_file),
                                    label: Text("Upload File"),
                                  ),
                                  if (selectedFileName.containsKey(id))
                                    Text("📎 Selected: ${selectedFileName[id]}"),
                                  SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => submitAssignment(assignment),
                                    icon: Icon(Icons.send),
                                    label: Text("Submit"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList()
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
