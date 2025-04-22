import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'dashboard_admin.dart';
import 'signup_admin.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({Key? key}) : super(key: key);

  @override
  _LoginAdminPageState createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  bool isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  Future<void> loginAdmin() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter both email and password")));
      return;
    }

    if (!isEmailValid(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid email address")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      AuthService authService = AuthService();
      var user = await authService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        if (!user.emailVerified) {
          await authService.logout();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please verify your email before logging in.")));
          return;
        }

        final schools = await FirebaseFirestore.instance.collection('schools').get();
        DocumentSnapshot? adminDoc;
        String foundSchoolDomain = '';
        String adminName = '';

        for (var school in schools.docs) {
          var adminSnapshot = await FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('admins')
              .doc(user.uid)
              .get();

          if (adminSnapshot.exists) {
            adminDoc = adminSnapshot;
            foundSchoolDomain = school.id;
            adminName = adminSnapshot['fullName'] ?? 'Admin';
            break;
          }
        }

        if (adminDoc != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardPage(
                schoolDomain: foundSchoolDomain,
                adminName: adminName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin profile not found.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid credentials")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    if (!isEmailValid(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid email to reset password")));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📩 Password reset email sent!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send reset email.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Welcome Admin!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            SizedBox(height: 20),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Login", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: resetPassword,
              child: Text("Forgot password? Reset here"),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpAdminPage()));
              },
              child: Text("Don't have an account? Sign Up here", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
