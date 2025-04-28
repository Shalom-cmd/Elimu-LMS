import 'dart:io'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_quiz_page.dart';

class ViewQuizzesPage extends StatefulWidget {
  const ViewQuizzesPage({Key? key}) : super(key: key);

  @override
  State<ViewQuizzesPage> createState() => _ViewQuizzesPageState();
}

class _ViewQuizzesPageState extends State<ViewQuizzesPage> {
  String schoolDomain = '';
  String grade = '';
  bool isLoading = true;
  Map<String, List<DocumentSnapshot>> groupedQuizzes = {};

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('teachers')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        schoolDomain = school.id;
        grade = doc['gradeLevel'];
        fetchQuizzes();
        break;
      }
    }
  }

  Future<void> fetchQuizzes() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('quizzes')
        .orderBy('dueDate')
        .get();

    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (var doc in snap.docs) {
      String subject = doc.data().toString().contains('subject')
          ? doc['subject']
          : 'Uncategorized';

      grouped.putIfAbsent(subject, () => []).add(doc);
    }

    setState(() {
      groupedQuizzes = grouped;
      isLoading = false;
    });
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    return DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
  }


  Future<void> openFileInNewTab(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file.')),
      );
    }
  }

  void openEditScreen(DocumentSnapshot quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQuizPage(quiz: quiz),
      ),
    );
  }

  void deleteQuiz(DocumentSnapshot quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("🗑️ Confirm Delete"),
        content: Text("Are you sure you want to delete '${quiz['title']}'?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await quiz.reference.delete();
      setState(() {
        final subject = quiz.data().toString().contains('subject')
            ? quiz['subject']
            : 'Uncategorized';

        groupedQuizzes[subject]?.removeWhere((doc) => doc.id == quiz.id);

        if (groupedQuizzes[subject]?.isEmpty ?? false) {
          groupedQuizzes.remove(subject);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Quiz deleted.")),
      );
    }
  }

  Color getSubjectColor(String subject) {
    final index = subject.hashCode % Colors.primaries.length;
    return Colors.primaries[index].shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🧠 View Quizzes")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedQuizzes.isEmpty
              ? Center(child: Text("No quizzes yet."))
              : ListView(
                  padding: EdgeInsets.all(12),
                  children: groupedQuizzes.entries.map((entry) {
                    final subject = entry.key;
                    final quizzes = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: getSubjectColor(subject),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...quizzes.map((quiz) {
                          final title = quiz['title'];
                          final type = quiz['type'];
                          final dueDate = formatDate(quiz['dueDate']);
                          final description = quiz['description'] ?? '';
                          final fileUrl = quiz['fileUrl'];
                          final inAppText = quiz.data().toString().contains('inAppQuizData')
                              ? quiz['inAppQuizData']
                              : null;

                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text("📅 Due: $dueDate",
                                      style: TextStyle(color: Colors.grey[700])),
                                  SizedBox(height: 10),
                                  if (type == "file" && fileUrl != null)
                                    ElevatedButton.icon(
                                      onPressed: () => openFileInNewTab(fileUrl),
                                      icon: Icon(Icons.open_in_new),
                                      label: Text("Open File"),
                                    ),
                                  if (type == "in-app" && inAppText != null)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      margin: EdgeInsets.only(top: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text("📋 In-app quiz available"),
                                    ),
                                  if (description.isNotEmpty) ...[
                                    SizedBox(height: 10),
                                    Text("📝 Notes: $description"),
                                  ],
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => openEditScreen(quiz),
                                        icon: Icon(Icons.edit),
                                        label: Text("Edit"),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => deleteQuiz(quiz),
                                        icon: Icon(Icons.delete_forever),
                                        label:
                                            Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
