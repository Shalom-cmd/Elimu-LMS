import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_roster_page.dart';
import '../landing_page.dart';
import '../../messaging/messaging_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'class_activity_overview_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String schoolDomain;
  final String adminName;

  const AdminDashboardPage({
    super.key,
    required this.schoolDomain,
    required this.adminName,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

  class _AdminDashboardPageState extends State<AdminDashboardPage> {
    String email = '';
    //String phone = '';
    String level = '';
    String schoolName = '';
    bool isLoading = true;
    String photoUrl = '';


    @override
    void initState() {
      super.initState();
      fetchAdminDetails();
    }

    Future<void> fetchAdminDetails() async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      try {
        final schoolDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolDomain)
            .get();

        final adminDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolDomain)
            .collection('admins')
            .doc(uid)
            .get();

        final schoolData = schoolDoc.data();
        final adminData = adminDoc.data();


        if (adminData != null && schoolData != null) {
          setState(() {
            email = adminData['email'] ?? '';
            //phone = adminData['phoneNumber'] ?? 'Unavailable';
            level = adminData['adminLevel'] ?? 'Admin';
            schoolName = schoolData['schoolName'] ?? widget.schoolDomain;
            photoUrl = adminData['photoUrl'] ?? '';
            isLoading = false;
          });
        }
      } catch (e) {
        print("❌ Failed to fetch admin details: $e");
      }
    }

  Future<void> chooseAvatarFromAssets() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final avatarPaths = List.generate(
          10,
          (index) => 'assets/images/admin_avatars/avatar${index + 1}.png',
        );
        return AlertDialog(
          title: Text("Choose Your Avatar"),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: GridView.count(
              crossAxisCount: 2,
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolDomain)
          .collection('admins')
          .doc(uid)
          .update({'photoUrl': selected});

      setState(() {
        photoUrl = selected;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Avatar selected!')),
      );
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }
  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Welcome, ${widget.adminName} 👋',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.school),
              title: Text('School Roster'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassRosterPage(schoolDomain: widget.schoolDomain),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.insights),
              title: Text("Class Activity Overview"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassActivityOverviewPage(schoolDomain: widget.schoolDomain),
                  ),
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
                      userId: adminId,
                      fullName: widget.adminName,
                      role: 'admin',
                      schoolDomain: widget.schoolDomain,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      
  body: isLoading
      ? Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "👋 Welcome Admin!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Avatar
              GestureDetector(
                onTap: chooseAvatarFromAssets,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: photoUrl.isEmpty
                          ? null
                          : AssetImage(photoUrl),
                      child: photoUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                      backgroundColor: Colors.grey[300],
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

              // Info Card
              Container(
                width: double.infinity,
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
                    Text("👩🏽‍💼 ${widget.adminName}",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInfoTile("📧 Email", email),
                    //_buildInfoTile("📞 Phone", phone),
                    _buildInfoTile("🔐 Admin Level", level),
                    _buildInfoTile("🏫 School", schoolName),
                    _buildInfoTile("🌐 Domain", widget.schoolDomain),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
