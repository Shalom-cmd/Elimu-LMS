import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_assignment_page.dart';
import 'view_assignments_page.dart';
import 'create_quiz_page.dart';
import 'view_quizzes_page.dart';
import 'class_resources_page.dart';
import 'grading_page.dart';
import '../../messaging/messaging_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<Map<String, dynamic>> students = [];
  String grade = '';
  String schoolDomain = '';
  String teacherName = '';

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
  }

  Future<void> fetchTeacherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schools = await FirebaseFirestore.instance.collection('schools').get();
    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('teachers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          grade = doc['gradeLevel'];
          schoolDomain = school.id;
          teacherName = doc['fullName'];
        });
        fetchStudents(school.id, doc['gradeLevel']);
        break;
      }
    }
  }

  Future<void> fetchStudents(String domain, String grade) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(domain)
        .collection('classes')
        .doc(grade)
        .collection('students')
        .get();

    setState(() {
      students = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📚 Teacher Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("👋 Hello,", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text(teacherName, style: const TextStyle(color: Colors.white, fontSize: 22)),
                  const Spacer(),
                  Text("Grade: $grade", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text("Class Resources"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassResourcesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Create Assignment"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAssignmentPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("View Assignments"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAssignmentsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("Create Quiz"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateQuizPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("View Quizzes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewQuizzesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("Grade Submissions"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GradingPage()),
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
                      fullName: teacherName,
                      role: 'teacher',
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👩🏽‍🏫 Welcome, $teacherName", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("🎓 Students in Grade $grade", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text("No students found in your class yet."))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(student['fullName'] ?? 'No Name'),
                            subtitle: Text("Username: ${student['username']}"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
