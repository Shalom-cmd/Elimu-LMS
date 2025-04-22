import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'dashboard_student.dart';
import 'signup_student.dart';

class LoginStudentPage extends StatefulWidget {
  const LoginStudentPage({Key? key}) : super(key: key);

  @override
  _LoginStudentPageState createState() => _LoginStudentPageState();
}

class _LoginStudentPageState extends State<LoginStudentPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? foundParentEmail; // for password reset

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Search all schools for the student by username
      final schools = await FirebaseFirestore.instance.collection('schools').get();
      DocumentSnapshot? studentDoc;

      for (var school in schools.docs) {
        final query = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('students')
            .where('username', isEqualTo: usernameController.text.trim())
            .get();

        if (query.docs.isNotEmpty) {
          studentDoc = query.docs.first;
          foundParentEmail = studentDoc['parentEmail'];
          break;
        }
      }

      if (studentDoc == null || foundParentEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ We couldn’t find your username. Please check your spelling.")),
        );
        return;
      }

      // Try login with parent's email
      AuthService authService = AuthService();
      var user = await authService.loginUser(foundParentEmail!, passwordController.text.trim());

      if (user != null) {
        if (!user.emailVerified) {
          await authService.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("📧 Please ask your parent to verify their email before logging in.")),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Login Successful!")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Your password was not correct, please try again.")),
        );
      }
    } catch (e) {
      print("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Something went wrong. Please try again.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter your username first.")));
      return;
    }

    try {
      // Reuse the logic to find parent email
      final schools = await FirebaseFirestore.instance.collection('schools').get();
      String? parentEmail;

      for (var school in schools.docs) {
        final query = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('students')
            .where('username', isEqualTo: usernameController.text.trim())
            .get();

        if (query.docs.isNotEmpty) {
          parentEmail = query.docs.first['parentEmail'];
          break;
        }
      }

      if (parentEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Could not find a parent email for that username.")),
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: parentEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📩 Password reset email sent to your parent's inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send password reset email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Login")),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "🎉 Welcome Back, Student!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 30),

              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "e.g. Emma-Grade 1",
                ),
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),

              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "e.g. TigerBlue7",
                ),
                obscureText: false,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              SizedBox(height: 10),

              TextButton(
                onPressed: resetPassword,
                child: Text("Forgot password? Reset it here", style: TextStyle(fontSize: 16)),
              ),

              SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpStudentPage()));
                },
                child: Text(
                  "Don't have an account? Sign up here!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),

              SizedBox(height: 30),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("💡 Fun Tip!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      SizedBox(height: 10),
                      Text(
                        "Use your special username (like Emma-Grade 1) and your fun password to log in!",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Your password is like a magic key that only you and your teacher know! 🔑✨",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
