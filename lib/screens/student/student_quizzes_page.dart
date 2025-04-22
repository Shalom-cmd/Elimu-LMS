import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<DocumentSnapshot> quizzes = [];
  Map<String, Map<int, dynamic>> selectedAnswers = {}; // dynamic to support int or text

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
        fetchQuizzes();
        break;
      }
    }
  }

  Future<void> fetchQuizzes() async {
    setState(() => isLoading = true);

    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('quizzes')
        .orderBy('dueDate')
        .get();

    final List<DocumentSnapshot> available = [];

    for (var quiz in snap.docs) {
      final submission = await quiz.reference.collection('submissions').doc(uid).get();
      if (!submission.exists) {
        available.add(quiz);
      }
    }

    setState(() {
      quizzes = available;
      isLoading = false;
    });
  }

    void submitQuiz(DocumentSnapshot quiz) async {
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
        'studentId': uid,
        'studentName': studentName,
        'answers': stringifiedAnswers,
        'submittedAt': FieldValue.serverTimestamp(),
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
            .set(submissionData);

        setState(() {
        quizzes.removeWhere((q) => q.id == quizId);
        selectedAnswers.remove(quizId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Quiz submitted!")),
        );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Submission failed: $e")),
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
                    final data = quiz.data() as Map<String, dynamic>;
                    final title = data['title'];
                    final subject = data['subject'];
                    final type = data['type'];
                    final inAppText = data['createdInAppText'] ?? '';
                    final fileUrl = data['fileUrl'];
                    final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
                    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();

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
                              TextButton.icon(
                                icon: Icon(Icons.link),
                                label: Text("Open Quiz File"),
                                onPressed: () => html.window.open(fileUrl, '_blank'),
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
                                              value: i,
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
