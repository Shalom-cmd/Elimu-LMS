import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewGradesPage extends StatefulWidget {
  const ViewGradesPage({Key? key}) : super(key: key);

  @override
  State<ViewGradesPage> createState() => _ViewGradesPageState();
}

class _ViewGradesPageState extends State<ViewGradesPage> {
  String schoolDomain = '';
  String grade = '';
  String uid = '';
  bool isLoading = true;

  List<Map<String, dynamic>> grades = [];

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    uid = user.uid;
    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('students')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        schoolDomain = school.id;
        grade = data['grade'];
        await fetchGrades();
        break;
      }
    }
  }

  Future<void> fetchGrades() async {
    final assignmentsSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('assignments')
        .get();

    final quizzesSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('quizzes')
        .get();

    List<Map<String, dynamic>> allGrades = [];

    for (var doc in assignmentsSnap.docs) {
      final submission = await doc.reference.collection('submissions').doc(uid).get();
      if (submission.exists && submission['grade'] != null) {
        allGrades.add({
          'title': doc['title'],
          'subject': doc['subject'],
          'type': 'Assignment',
          'grade': submission['grade'],
        });
      }
    }

    for (var doc in quizzesSnap.docs) {
      final submission = await doc.reference.collection('submissions').doc(uid).get();
      if (submission.exists && submission['grade'] != null) {
        allGrades.add({
          'title': doc['title'],
          'subject': doc['subject'],
          'type': 'Quiz',
          'grade': submission['grade'],
        });
      }
    }

    setState(() {
      grades = allGrades;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📊 My Grades")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : grades.isEmpty
              ? Center(child: Text("No grades available yet."))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    return Card(
                      child: ListTile(
                        title: Text("${grade['title']} (${grade['type']})"),
                        subtitle: Text("📘 ${grade['subject']}"),
                        trailing: Text("🎯 ${grade['grade']}", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}
