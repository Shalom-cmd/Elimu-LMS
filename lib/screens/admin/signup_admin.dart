import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'login_admin.dart';

class SignUpAdminPage extends StatefulWidget {
  const SignUpAdminPage({Key? key}) : super(key: key);

  @override
  _SignUpAdminPageState createState() => _SignUpAdminPageState();
}

class _SignUpAdminPageState extends State<SignUpAdminPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController adminLevelController = TextEditingController();
  final TextEditingController schoolDomainController = TextEditingController();

  bool isLoading = false;

  Future<void> registerAdmin() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid email address")));
      return;
    }

    if (adminLevelController.text.trim().isEmpty || !["Super Admin", "School Admin"].contains(adminLevelController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a valid admin level (Super Admin/School Admin)")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      AuthService authService = AuthService();
      var user = await authService.signUpUser(
        emailController.text.trim(),
        passwordController.text.trim(),
        "admins",
        "", // No username for admins
        schoolDomainController.text.trim(),
      );

      if (user != null) {
        String schoolDomain = schoolDomainController.text.trim();

        var schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(schoolDomain).get();
        if (!schoolDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("School domain not found. Please register the school first.")));
          setState(() {
            isLoading = false;
          });
          return;
        }

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('admins')
            .doc(user.uid)
            .set({
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'adminLevel': adminLevelController.text.trim(),
          'schoolDomain': schoolDomain,
          'role': "admin",
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Admin Registered! Please verify your email before logging in.")),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginAdminPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Sign-up failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Sign-Up")),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            TextField(controller: confirmPasswordController, decoration: InputDecoration(labelText: "Confirm Password"), obscureText: true),
            TextField(controller: adminLevelController, decoration: InputDecoration(labelText: "Admin Level (Super Admin/School Admin)")),
            TextField(controller: schoolDomainController, decoration: InputDecoration(labelText: "Enter School Domain")),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: registerAdmin, child: Text("Sign Up")),
          ],
        ),
      ),
    );
  }
}
