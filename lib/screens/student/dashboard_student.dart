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
  String parentEmailDisplay = '';
  String schoolName = '';
  int assignmentsCount = 0;
  int quizzesCount = 0;
  String uid = '';

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
    final box = Hive.box('profileBox');

    if (user == null) {
      // Offline fallback
      final cached = box.get('studentProfile');
      if (cached != null) {
        setState(() {
          studentName = cached['fullName'] ?? '';
          grade = cached['grade'] ?? '';
          schoolName = cached['schoolName'] ?? 'Unavailable offline';
          teacherName = cached['teacherName'] ?? 'Unavailable offline';
          parentEmailDisplay = cached['parentEmail'] ?? 'Unavailable offline';
          photoUrl = cached['photoUrl'] ?? '';
          schoolDomain = cached['schoolDomain'] ?? '';
          isLoading = false;
        });
      }
      return;
    }
    try {
      uid = user.uid;
      // Try cached school domain first
      final cachedProfile = box.get('studentProfile');
      String? cachedDomain = cachedProfile?['schoolDomain'];

      if (cachedDomain == null || cachedDomain.isEmpty) {
        // fallback: loop through schools once and cache it
        final schools = await FirebaseFirestore.instance.collection('schools').get();
        for (var school in schools.docs) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('students')
              .doc(uid)
              .get();

          if (studentDoc.exists) {
            cachedDomain = school.id;
            break;
          }
        }
      }

      if (cachedDomain == null || cachedDomain.isEmpty) throw Exception('Student domain not found');

      final studentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(cachedDomain)
          .collection('students')
          .doc(uid)
          .get();

      if (!studentDoc.exists) throw Exception('Student profile not found');

      final studentData = studentDoc.data()!;
      final fullName = studentData['fullName'];
      final gradeLevel = studentData['grade'];
      final parentEmail = studentData['parentEmail'] ?? 'Unavailable';
      final profilePic = studentData['photoUrl'] ?? '';

      final schoolData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(cachedDomain)
          .get();

      final schoolDisplayName = schoolData.data()?['schoolName'] ?? cachedDomain;

      final teacherSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(cachedDomain)
          .collection('teachers')
          .where('gradeLevel', isEqualTo: gradeLevel)
          .limit(1)
          .get();

      final teacher = teacherSnapshot.docs.isNotEmpty
          ? teacherSnapshot.docs.first['fullName']
          : 'Unknown';

      // Save to Hive
      await box.put('studentProfile', {
        'uid': uid,
        'fullName': fullName,
        'grade': gradeLevel,
        'schoolName': schoolDisplayName,
        'schoolDomain': cachedDomain, 
        'teacherName': teacher,
        'parentEmail': parentEmail,
        'photoUrl': profilePic,
      });

      setState(() {
        studentName = fullName;
        grade = gradeLevel;
        schoolName = schoolDisplayName;
        schoolDomain = cachedDomain!;
        teacherName = teacher;
        parentEmailDisplay = parentEmail;
        photoUrl = profilePic;
        isLoading = false;
      });
    } catch (e) {
      print("⚠️ Error fetching student info: $e");
      final cached = box.get('studentProfile');
      if (cached != null) {
        setState(() {
          studentName = cached['fullName'] ?? '';
          grade = cached['grade'] ?? '';
          schoolName = cached['schoolName'] ?? 'Unavailable';
          schoolDomain = cached['schoolDomain'] ?? '';
          teacherName = cached['teacherName'] ?? 'Unavailable';
          parentEmailDisplay = cached['parentEmail'] ?? 'Unavailable';
          photoUrl = cached['photoUrl'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  Future<void> chooseAvatarFromAssets() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final avatarPaths = List.generate(
          10,
          (index) => 'assets/images/student_avatars/avatar${index + 1}.png',
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
      // upload to Firestore or Hive
      setState(() {
        photoUrl = selected; 
      });

      final user = FirebaseAuth.instance.currentUser;
      final schools = await FirebaseFirestore.instance.collection('schools').get();
      for (var school in schools.docs) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('students')
            .doc(user!.uid)
            .get();

        if (studentDoc.exists) {
          await studentDoc.reference.update({'photoUrl': selected});
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
                const Text("👋 Hello,", style: TextStyle(color: Colors.white, fontSize: 20)),
                Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 22)),
                const Spacer(),
                Text("Grade: $grade", style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
            ListTile(
              leading: const Icon(Icons.folder_copy),
              title: const Text("Class Resources 📚"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentResourcesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Assignments 📝"),
              onTap: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentAssignmentsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text("Quizzes 🧠"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentQuizzesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.grade),
              title: Text("Grades 📊"),
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
              enabled: !isLoading && schoolDomain.isNotEmpty,
              onTap: () {
                if (schoolDomain.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Not Ready Yet'),
                      content: Text('Please wait for your profile to finish loading.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

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
      : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
              GestureDetector(
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
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                const SizedBox(height: 24),

                // Profile card
                Container(
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
                      Text(
                        "👋 Hello, $studentName",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.school, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "School: $schoolName",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(Icons.menu_book, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text("Grade: $grade", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(Icons.person_pin, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text("Teacher: $teacherName",
                              style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Parent Email: $parentEmailDisplay",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }