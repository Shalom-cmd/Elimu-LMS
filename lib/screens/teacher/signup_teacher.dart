import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'login_teacher.dart';

class SignUpTeacherPage extends StatefulWidget {
  const SignUpTeacherPage({Key? key}) : super(key: key);

  @override
  _SignUpTeacherPageState createState() => _SignUpTeacherPageState();
}

class _SignUpTeacherPageState extends State<SignUpTeacherPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController gradeLevelController = TextEditingController();
  final TextEditingController schoolDomainController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController emergencyContactNameController = TextEditingController();
  final TextEditingController emergencyContactPhoneController = TextEditingController();
  final TextEditingController emergencyContactEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> registerTeacher() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Passwords do not match!")));
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
        "teachers", // this should match your Firestore collection: 'teachers'
        "", // username is empty for now
        schoolDomainController.text.trim(),
      );

      if (user != null) {
        String schoolDomain = schoolDomainController.text.trim();
        String grade = gradeLevelController.text.trim();

        // Save full profile under 'teachers'
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('teachers')
            .doc(user.uid)
            .set({
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'gradeLevel': grade,
          'school': schoolDomain,
          'homeAddress': homeAddressController.text.trim(),
          'emergencyContactName': emergencyContactNameController.text.trim(),
          'emergencyContactPhone': emergencyContactPhoneController.text.trim(),
          'emergencyContactEmail': emergencyContactEmailController.text.trim(),
          'role': "teacher",
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Summary in classes > grade > teachers
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('classes')
            .doc(grade)
            .collection('teachers')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'grade': grade,
          'schoolDomain': schoolDomain,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Registration successful! Please verify your email before logging in.")),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginTeacherPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Sign-up failed.")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error occurred. Please try again.")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teacher Sign-Up")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: phoneNumberController, decoration: InputDecoration(labelText: "Phone Number")),
            TextField(
              controller: gradeLevelController,
              decoration: InputDecoration(
                labelText: "What grade level do you teach?",
                hintText: "e.g. Kindergarten, Grade 1, Grade 2",
              ),
            ),
            TextField(
              controller: schoolDomainController,
              decoration: InputDecoration(
                labelText: "School Domain",
                hintText: "e.g. chicoelementary.edu",
              ),
            ),
            TextField(controller: homeAddressController, decoration: InputDecoration(labelText: "Home Address")),
            SizedBox(height: 20),
            Text("📞 Emergency Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: emergencyContactNameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: emergencyContactPhoneController, decoration: InputDecoration(labelText: "Phone")),
            TextField(controller: emergencyContactEmailController, decoration: InputDecoration(labelText: "Email")),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm Password"),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
