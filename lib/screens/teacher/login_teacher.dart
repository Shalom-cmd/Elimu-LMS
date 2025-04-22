import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import 'dashboard_teacher.dart';
import 'signup_teacher.dart';

class LoginTeacherPage extends StatefulWidget {
  const LoginTeacherPage({Key? key}) : super(key: key);

  @override
  _LoginTeacherPageState createState() => _LoginTeacherPageState();
}

class _LoginTeacherPageState extends State<LoginTeacherPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  Future<void> loginUser() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Login Successful!")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Login failed. Email might not be verified."))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Login error. Please try again.")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📧 Please enter your email first.")));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📩 Password reset email sent.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to send reset email.")));
    }
  }

  Future<void> resendVerification() async {
    try {
      var user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📧 Verification email resent.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Email already verified or user not logged in.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Could not resend verification email.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teacher Login")),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome Back! 🎉",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 18),
              ),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
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
              SizedBox(height: 20),
              TextButton(
                onPressed: resetPassword,
                child: Text("Forgot password? Reset here", style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: resendVerification,
                child: Text("Resend verification email", style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpTeacherPage()));
                },
                child: Text("Don't have an account? Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
