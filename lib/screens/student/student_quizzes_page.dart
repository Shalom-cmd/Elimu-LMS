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
import '../../models/quiz.dart';

class StudentQuizzesPage extends StatefulWidget {
  const StudentQuizzesPage({Key? key}) : super(key: key);

  @override
  State<StudentQuizzesPage> createState() => _StudentQuizzesPageState();
}

class _StudentQuizzesPageState extends State<StudentQuizzesPage> {
  String schoolDomain = '';
  String grade = '';
  String uid = '';
  String studentName = '';
  bool isLoading = true;

  List<Quiz> quizzes = [];
  Map<String, Map<int, dynamic>> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
    resendPendingSubmissions(); 
  }

  Future<void> resendPendingSubmissions() async {
  final pendingBox = await Hive.openBox('pendingSubmissions');
  final List pending = pendingBox.values.toList();

  if (pending.isEmpty) return;

  for (var submission in pending) {
    try {
      if (submission['type'] == 'quiz') {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(submission['schoolDomain'])
            .collection('classes')
            .doc(submission['grade'])
            .collection('quizzes')
            .doc(submission['quizId'])
            .collection('submissions')
            .doc(submission['uid'])
            .set({
              'studentId': submission['uid'],
              'studentName': submission['studentName'],
              'answers': Map<String, dynamic>.from(submission['answers'].map((key, value) => MapEntry(key.toString(), value.toString()))),
              'submittedAt': FieldValue.serverTimestamp(),
            });

        
        final key = pendingBox.keys.firstWhere((k) => pendingBox.get(k) == submission);
        await pendingBox.delete(key);
        print('✅ Resent pending quiz submission.');
      }
      
    } catch (e) {
      print('❌ Failed to resend pending submission: $e');
    }
  }
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
        fetchQuizzes();
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
        schoolDomain = school.id;
        grade = data['grade'];
        studentName = data['fullName'];
        uid = studentId;

        // Save for offline
        await profileBox.put('studentProfile', {
          'uid': uid,
          'fullName': studentName,
          'grade': grade,
          'schoolDomain': schoolDomain,
        });

        fetchQuizzes();
        break;
      }
    }
  }


  Future<void> openQuizFile(String url, String quizId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/quiz_$quizId.pdf');

      if (await file.exists()) {
        print('📄 Opening cached file for quiz $quizId');
        await OpenFile.open(file.path);
      } else {
        print('⬇️ Downloading quiz file for $quizId: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('✅ Quiz file saved locally: ${file.path}');
          await OpenFile.open(file.path);
        } else {
          print('❌ Failed to download file. Status: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not download quiz file.')));
        }
      }
    } catch (e) {
      print('❌ Error opening quiz file: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening quiz file.')));
    }
  }

  Future<void> fetchQuizzes() async {
    setState(() => isLoading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('quizzes')
          .orderBy('dueDate')
          .get(const GetOptions(source: Source.serverAndCache)); 

      final List<Quiz> available = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        available.add(Quiz(
          id: doc.id,
          title: data['title'] ?? '',
          subject: data['subject'] ?? '',
          type: data['type'] ?? 'file',
          createdInAppText: data['createdInAppText'],
          fileUrl: data['fileUrl'],
          questions: List<Map<String, dynamic>>.from(data['questions'] ?? []),
          dueDate: (data['dueDate'] as Timestamp?)?.toDate().toIso8601String() ?? '',
        ));
      }

      await saveQuizzesToHive(available);
      print('✅ Saved ${available.length} quizzes to Hive');

      setState(() {
        quizzes = available;
        isLoading = false;
      });
    } catch (e) {
      print('🔥 Firestore failed, loading from Hive: $e');

      final cached = loadQuizzesFromHive();
      print('📦 Loaded ${cached.length} quizzes from Hive');
      for (var q in cached) {
        print('🧠 Quiz: ${q.title}');
      }

      setState(() {
        quizzes = cached;
        isLoading = false;
      });
    }
  }


  Future<void> uploadFileAnswer(String quizId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final filePath = file.path!;
      final fileName = file.name;

      final ref = FirebaseStorage.instance
        .ref()
        .child('quiz_submissions/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await ref.putFile(File(filePath));
      final fileUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        selectedAnswers.putIfAbsent(quizId, () => {});
        selectedAnswers[quizId]![0] = fileUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ File uploaded! Ready to submit.")),
      );
    }
  }
  void submitQuiz(Quiz quiz) async {
    final quizId = quiz.id;
    final answers = selectedAnswers[quizId];

    if (answers == null || answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please answer all questions before submitting.")),
      );
      return;
    }

    try {
      final stringifiedAnswers = answers.map((key, value) => MapEntry(key.toString(), value.toString()));

      final submissionData = {
        'type': 'quiz',
        'studentId': uid,
        'studentName': studentName,
        'quizId': quizId,
        'schoolDomain': schoolDomain,
        'grade': grade,
        'answers': stringifiedAnswers,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('quizzes')
          .doc(quizId)
          .collection('submissions')
          .doc(uid)
          .set({
            'studentId': uid,
            'studentName': studentName,
            'answers': stringifiedAnswers,
            'submittedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        quizzes.removeWhere((q) => q.id == quizId);
        selectedAnswers.remove(quizId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Quiz submitted!")),
      );
    } catch (e) {
      print('❌ Submission failed, saving locally: $e');

      final pendingBox = await Hive.openBox('pendingSubmissions');
      await pendingBox.add({
        'type': 'quiz',
        'quizId': quizId,
        'schoolDomain': schoolDomain,
        'grade': grade,
        'uid': uid,
        'studentName': studentName,
        'answers': answers,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved offline. Will auto-submit when online.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📝 My Quizzes")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
              ? Center(child: Text("No quizzes available."))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final title = quiz.title;
                    final subject = quiz.subject;
                    final type = quiz.type;
                    final inAppText = quiz.createdInAppText ?? '';
                    final fileUrl = quiz.fileUrl;
                    final questions = quiz.questions ?? [];
                    final dueDate = DateTime.tryParse(quiz.dueDate);
                    return Card(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📘 $subject", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("📝 $title", style: TextStyle(fontSize: 18)),
                            if (dueDate != null) Text("📅 Due: ${dueDate.toLocal()}"),
                            SizedBox(height: 10),
                            if (type == "file" && fileUrl != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.picture_as_pdf),
                                    label: Text("Open Quiz File"),
                                    onPressed: () => openQuizFile(fileUrl!, quiz.id),
                                  ),
                                  TextField(
                                    decoration: InputDecoration(hintText: "Write your answer here..."),
                                    maxLines: 3,
                                    onChanged: (val) {
                                      selectedAnswers.putIfAbsent(quiz.id, () => {});
                                      selectedAnswers[quiz.id]![0] = val.trim();
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.upload_file),
                                    label: Text("Upload File Instead"),
                                    onPressed: () => uploadFileAnswer(quiz.id),
                                  ),
                                ],
                              ),
                            if (type == "in-app" && questions.isNotEmpty)
                              Column(
                                children: List.generate(questions.length, (qIndex) {
                                  final q = questions[qIndex];
                                  final qText = q['question'];
                                  final options = List<String>.from(q['options'] ?? []);
                                  final isMCQ = options.any((o) => o.trim().isNotEmpty);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Q${qIndex + 1}: $qText"),
                                      if (isMCQ)
                                        Column(
                                          children: List.generate(options.length, (i) {
                                            return RadioListTile(
                                              title: Text(options[i]),
                                              value: options[i],
                                              groupValue: selectedAnswers[quiz.id]?[qIndex],
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedAnswers.putIfAbsent(quiz.id, () => {});
                                                  selectedAnswers[quiz.id]![qIndex] = val!;
                                                });
                                              },
                                            );
                                          }),
                                        ),
                                      if (!isMCQ)
                                        TextField(
                                          decoration: InputDecoration(hintText: "Your answer"),
                                          onChanged: (val) {
                                            selectedAnswers.putIfAbsent(quiz.id, () => {});
                                            selectedAnswers[quiz.id]![qIndex] = val.trim();
                                          },
                                        ),
                                      SizedBox(height: 16),
                                    ],
                                  );
                                }),
                              ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => submitQuiz(quiz),
                              icon: Icon(Icons.check),
                              label: Text("Submit"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
