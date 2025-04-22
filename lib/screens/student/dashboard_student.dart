import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_resources_page.dart';
import 'student_assignments_page.dart';
import 'student_quizzes_page.dart';
import 'view_grades_page.dart';
import '../../messaging/messaging_screen.dart';


class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String studentName = '';
  String grade = '';
  String schoolDomain = '';
  String teacherName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final studentData = doc.data()!;
        final gradeLevel = studentData['grade'];

        final teacherSnapshot = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('teachers')
            .where('gradeLevel', isEqualTo: gradeLevel)
            .limit(1)
            .get();

        setState(() {
          studentName = studentData['fullName'];
          grade = gradeLevel;
          schoolDomain = school.id;
          teacherName = teacherSnapshot.docs.isNotEmpty
              ? teacherSnapshot.docs.first['fullName']
              : 'Unknown';
          isLoading = false;
        });

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎓 Student Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome,", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 22)),
                  const Spacer(),
                  Text("Grade: $grade", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_copy),
              title: const Text("Class Resources"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentResourcesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Assignments"),
              onTap: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentAssignmentsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text("Quizzes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentQuizzesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.grade),
              title: Text("Grades"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewGradesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Messages'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagingScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      fullName: studentName,
                      role: 'student',
                      schoolDomain: schoolDomain,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👋 Hello, $studentName", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("📘 Grade: $grade", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("👩🏽‍🏫 Your Teacher: $teacherName", style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }
}
