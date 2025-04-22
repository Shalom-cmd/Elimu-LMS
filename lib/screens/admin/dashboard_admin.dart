import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_roster_page.dart';
import '../landing_page.dart';
import '../../messaging/messaging_screen.dart';

class AdminDashboardPage extends StatelessWidget {
  final String schoolDomain;
  final String adminName;

  const AdminDashboardPage({
    super.key,
    required this.schoolDomain,
    required this.adminName,
  });

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
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
                'Welcome, $adminName 👋',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.school),
              title: Text('Class Roster'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassRosterPage(schoolDomain: schoolDomain),
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
                      fullName: adminName,
                      role: 'admin',
                      schoolDomain: schoolDomain,
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $adminName 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              "Use the ☰ menu to access management tools.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
