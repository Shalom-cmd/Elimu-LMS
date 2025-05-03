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

      if (data.containsKey('grade') && data['grade'] != null) {
        grade = data['grade'];
        schoolDomain = school.id;
        await fetchGrades();
      } else {
        print('⚠️ Missing "grade" for student: $uid');
      }

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
    final submissionData = submission.data();
    if (submission.exists && submissionData != null && submissionData.containsKey('grade')) {
      allGrades.add({
        'title': doc['title'],
        'subject': doc['subject'],
        'type': 'Assignment',
        'grade': submissionData['grade'],
      });
    }
  }

  for (var doc in quizzesSnap.docs) {
    final submission = await doc.reference.collection('submissions').doc(uid).get();
    final submissionData = submission.data();
    if (submission.exists && submissionData != null && submissionData.containsKey('grade')) {
      allGrades.add({
        'title': doc['title'],
        'subject': doc['subject'],
        'type': 'Quiz',
        'grade': submissionData['grade'],
      });
    }
  }
    setState(() {
      grades = allGrades;
      isLoading = false;
    });
  }

  @override
@override
Widget build(BuildContext context) {
  final assignmentGrades = grades.where((g) => g['type'] == 'Assignment').toList();
  final quizGrades = grades.where((g) => g['type'] == 'Quiz').toList();

  return Scaffold(
    appBar: AppBar(title: Text("📊 My Grades")),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : grades.isEmpty
            ? Center(child: Text("No grades available yet."))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (assignmentGrades.isNotEmpty) ...[
                      Text("📝 Assignments", style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 8),
                      ...assignmentGrades.map(buildGradeCard),
                      SizedBox(height: 20),
                    ],
                    if (quizGrades.isNotEmpty) ...[
                      Text("🏆 Quizzes", style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 8),
                      ...quizGrades.map(buildGradeCard),
                    ],
                  ],
                ),
              ),
  );
}

  Widget buildGradeCard(Map<String, dynamic> grade) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          grade['type'] == 'Assignment' ? Icons.assignment : Icons.quiz,
          color: grade['type'] == 'Assignment' ? Colors.blue : Colors.deepPurple,
          size: 30,
        ),
        title: Text(grade['title'], style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("📘 ${grade['subject']}"),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            grade['grade'],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
          ),
        ),
      ),
    );
  }
}
