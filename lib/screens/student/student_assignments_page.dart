import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Map<String, List<DocumentSnapshot>> groupedAssignments = {};
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
    if (user == null) return;

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
        schoolDomain = school.id;
        grade = data['grade'];
        studentName = data['fullName'];
        uid = studentId;
        fetchAssignments();
        break;
      }
    }
  }

  Future<void> fetchAssignments() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('assignments')
        .orderBy('dueDate')
        .get();

    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (var doc in snap.docs) {
      final submission = await doc.reference
          .collection('submissions')
          .doc(uid)
          .get();

      // Skip if already submitted
      if (submission.exists) continue;

      final subject = doc['subject'] ?? 'Uncategorized';
      grouped.putIfAbsent(subject, () => []).add(doc);
      textControllers[doc.id] = TextEditingController();
    }
    setState(() {
      groupedAssignments = grouped;
      isLoading = false;
    });
  }

  void pickFile(String assignmentId) {
    final uploadInput = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file!);
      reader.onLoadEnd.listen((_) {
        setState(() {
          selectedFileBytes[assignmentId] = reader.result as Uint8List;
          selectedFileName[assignmentId] = file.name;
        });
      });
    });
  }

  Future<void> submitAssignment(DocumentSnapshot assignment) async {
    final assignmentId = assignment.id;
    final textAnswer = textControllers[assignmentId]?.text.trim() ?? "";
    final file = selectedFileBytes[assignmentId];
    final fileName = selectedFileName[assignmentId];

    if (textAnswer.isEmpty && file == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please upload a file or enter a text answer.")));
      return;
    }

    String? fileUrl;
    if (file != null && fileName != null) {
      final ref = FirebaseStorage.instance
          .ref('submissions/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');
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
    // Remove the assignment from the local groupedAssignments map
    final subject = assignment['subject'] ?? 'Uncategorized';
    groupedAssignments[subject]?.removeWhere((doc) => doc.id == assignmentId);

    // Clean up the subject group if empty
    if (groupedAssignments[subject]?.isEmpty ?? false) {
      groupedAssignments.remove(subject);
    }

    textControllers.remove(assignmentId);
    selectedFileBytes.remove(assignmentId);
    selectedFileName.remove(assignmentId);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Assignment submitted!")));
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
                          final title = assignment['title'];
                          final description = assignment['description'] ?? '';
                          final inAppText = assignment['createdInAppText'] ?? '';
                          final fileUrl = assignment['fileUrl'];
                          final type = assignment['type'];

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
                                      onPressed: () => html.window.open(fileUrl, "_blank"),
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
