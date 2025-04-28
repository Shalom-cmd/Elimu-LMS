import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'dart:typed_data'; 
import 'package:hive/hive.dart'; 
import 'student_resources_page.dart';
import 'student_assignments_page.dart';
import 'student_quizzes_page.dart';
import 'view_grades_page.dart';
import '../../messaging/messaging_screen.dart';
import '../landing_page.dart';

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
  String photoUrl = '';
  bool isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }
  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // offline fallback
      final box = Hive.box('profileBox');
      final cached = box.get('studentProfile');

      if (cached != null) {
        setState(() {
          studentName = cached['fullName'] ?? '';
          grade = cached['grade'] ?? '';
          schoolDomain = cached['schoolDomain'] ?? '';
          teacherName = 'Unavailable offline';
          isLoading = false;
        });
      }
      return;
    }

    // 🌐 Online path
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
        final box = Hive.box('profileBox');
        await box.put('studentProfile', {
          'uid': user.uid,
          'fullName': studentData['fullName'],
          'grade': gradeLevel,
          'schoolDomain': school.id,
        });

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

  Future<void> pickAndUploadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        isUploadingPhoto = true;
      });

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putData(result.files.single.bytes!);

        final downloadUrl = await uploadTask.ref.getDownloadURL();

        // Save new photoUrl to Firestore
        final schools = await FirebaseFirestore.instance.collection('schools').get();
        for (var school in schools.docs) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('students')
              .doc(user.uid)
              .get();

          if (studentDoc.exists) {
            await studentDoc.reference.update({'photoUrl': downloadUrl});
            setState(() {
              photoUrl = downloadUrl;
            });

            final box = Hive.box('profileBox');
            final cachedProfile = box.get('studentProfile');
            if (cachedProfile != null) {
              cachedProfile['photoUrl'] = downloadUrl;
              await box.put('studentProfile', cachedProfile);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Profile picture updated!')),
            );
            break;
          }
        }
      } catch (e) {
        print('❌ Failed to upload profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to upload picture. Try again later.')),
        );
      } finally {
        setState(() {
          isUploadingPhoto = false;
        });
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
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hello,", style: TextStyle(color: Colors.white, fontSize: 20)),
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
              onTap: () => logout(context),
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
                  Center(
                  child: GestureDetector(
                    onTap: isUploadingPhoto ? null : pickAndUploadProfilePicture,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50, 
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                          backgroundColor: Colors.grey[300],
                        ),
                        if (isUploadingPhoto)
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: 20),
                  Text(
                    "👋 Hello, $studentName",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "📘 Grade: $grade",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "👩🏽‍🏫 Your Teacher: $teacherName",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
      );
    }
  }