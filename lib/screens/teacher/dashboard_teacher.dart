import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data'; 
import 'create_assignment_page.dart';
import 'view_assignments_page.dart';
import 'create_quiz_page.dart';
import 'view_quizzes_page.dart';
import 'class_resources_page.dart';
import 'grading_page.dart';
import '../../messaging/messaging_screen.dart';
import '../landing_page.dart';

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
  String teacherEmail = '';
  String teacherPhone = '';
  String photoUrl = '';
  String schoolName = '';
  bool isUploadingPhoto = false;


  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
  }
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
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
          final data = doc.data()!;
          final gradeLevel = data['gradeLevel'];
          final name = data['fullName'];
          final email = data['email'] ?? 'Unavailable';
          final phone = data['phoneNumber'] ?? 'Unavailable';
          final photo = data['photoUrl'] ?? '';

          final schoolData = school.data();
          final displayName = schoolData['schoolName'] ?? school.id;

          setState(() {
            grade = gradeLevel;
            teacherName = name;
            teacherEmail = email;
            teacherPhone = phone;
            photoUrl = photo;
            schoolDomain = school.id;
            schoolName = displayName;
          });

          fetchStudents(school.id, gradeLevel);
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
      setState(() => isUploadingPhoto = true);

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putData(result.files.single.bytes!);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        final teacherRef = FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('teachers')
            .doc(user.uid);

        await teacherRef.update({'photoUrl': downloadUrl});

        setState(() {
          photoUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile picture updated!')),
        );
      } catch (e) {
        print('❌ Failed to upload profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Upload failed. Please try again.')),
        );
      } finally {
        setState(() => isUploadingPhoto = false);
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

  Future<void> chooseAvatarFromAssets() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final avatarPaths = List.generate(
          10,
          (index) => 'assets/images/teacher_avatars/avatar${index + 1}.png',
        );
        return AlertDialog(
          title: Text("Choose Your Avatar"),
          content: SizedBox(
            height: 300, 
            width: double.maxFinite,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true, 
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: avatarPaths.map((path) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, path),
                  child: ClipOval( 
                    child: Image.asset(path, fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      // optionally upload to Firestore or Hive
      setState(() {
        photoUrl = selected; 
      });

      final user = FirebaseAuth.instance.currentUser;
      final schools = await FirebaseFirestore.instance.collection('schools').get();
      for (var school in schools.docs) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('teachers')
            .doc(user!.uid)
            .get();

        if (teacherDoc.exists) {
          await teacherDoc.reference.update({'photoUrl': selected});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Avatar selected!')),
          );
          break;
        }
      }
    }
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
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Profile Section
        Center(
          child: GestureDetector(
            onTap: isUploadingPhoto ? null : chooseAvatarFromAssets,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: photoUrl.isEmpty
                      ? null
                      : photoUrl.startsWith('assets/')
                          ? AssetImage(photoUrl)
                          : NetworkImage(photoUrl) as ImageProvider,
                  child: photoUrl.isEmpty
                      ? Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                  backgroundColor: Colors.grey[300],
                ),
                if (isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 🧾 Profile card
        Center(
          child: Container(
            width: 360, // optional: control card width for large screens
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("👩🏽‍🏫 $teacherName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("📧 $teacherEmail", style: const TextStyle(fontSize: 16)),
                Text("📞 $teacherPhone", style: const TextStyle(fontSize: 16)),
                Text("🏫 $schoolName", style: const TextStyle(fontSize: 16)),
                Text("📘 Grade: $grade", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // 👩‍🎓 Students section
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


