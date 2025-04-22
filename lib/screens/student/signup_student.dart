import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'login_student.dart';

class SignUpStudentPage extends StatefulWidget {
  const SignUpStudentPage({Key? key}) : super(key: key);

  @override
  _SignUpStudentPageState createState() => _SignUpStudentPageState();
}

class _SignUpStudentPageState extends State<SignUpStudentPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController parentEmailController = TextEditingController();
  final TextEditingController parentPhoneNumberController = TextEditingController();
  final TextEditingController schoolDomainController = TextEditingController();

  final TextEditingController studentFirstNameController = TextEditingController();
  final TextEditingController favoriteAnimalController = TextEditingController();
  final TextEditingController favoriteColorController = TextEditingController();
  final TextEditingController favoriteNumberController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String generatedUsername = "";
  String generatedPassword = "";
  bool isLoading = false;

  String generateUsername(String firstName, String grade) {
    String capitalizedFirst = firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    String cleanGrade = grade.trim();
    return "$capitalizedFirst-$cleanGrade";
  }

  String generatePassword(String animal, String color, String number) {
    return "${animal[0].toUpperCase()}${animal.substring(1)}"
        "${color[0].toUpperCase()}${color.substring(1)}"
        "$number";
  }

  void createStudentAccount() async {
    if (generatedUsername.isEmpty || generatedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please generate a username & password first!")));
      return;
    }

    if (generatedPassword != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      AuthService authService = AuthService();
      var user = await authService.signUpUser(
        parentEmailController.text.trim(),
        generatedPassword,
        "students",
        generatedUsername,
        schoolDomainController.text.trim(),
      );

      if (user != null) {
        String schoolDomain = schoolDomainController.text.trim();
        String grade = gradeController.text.trim();

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('students')
            .doc(user.uid)
            .set({
          'fullName': "${firstNameController.text.trim()} ${lastNameController.text.trim()}",
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'grade': grade,
          'address': addressController.text.trim(),
          'parentEmail': parentEmailController.text.trim(),
          'parentPhoneNumber': parentPhoneNumberController.text.trim(),
          'schoolDomain': schoolDomain,
          'username': generatedUsername,
          'role': "student",
          'uid': user.uid,
        });

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDomain)
            .collection('classes')
            .doc(grade)
            .collection('students')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'fullName': "${firstNameController.text.trim()} ${lastNameController.text.trim()}",
          'username': generatedUsername,
          'grade': grade,
          'schoolDomain': schoolDomain,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Account created! Please verify your parent's email before logging in.")),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginStudentPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Sign-up failed")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Something went wrong. Please try again.")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // No layout changes needed here.
    return Scaffold(
      appBar: AppBar(title: Text("Student Sign-Up")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👩‍🏫 To be filled out by teacher/parent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: firstNameController, decoration: InputDecoration(labelText: "First Name")),
            TextField(controller: lastNameController, decoration: InputDecoration(labelText: "Last Name")),
            TextField(controller: gradeController, decoration: InputDecoration(labelText: "Grade")),
            TextField(controller: addressController, decoration: InputDecoration(labelText: "Address")),
            TextField(controller: parentEmailController, decoration: InputDecoration(labelText: "Parent Email")),
            TextField(controller: parentPhoneNumberController, decoration: InputDecoration(labelText: "Parent Phone Number")),
            TextField(controller: schoolDomainController, decoration: InputDecoration(labelText: "School Domain")),

            SizedBox(height: 20),
            Text("🧒 For the student", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: studentFirstNameController, decoration: InputDecoration(labelText: "Your First Name")),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  generatedUsername = generateUsername(studentFirstNameController.text.trim(), gradeController.text.trim());
                });
              },
              child: Text("Generate Username"),
            ),
            Text("Generated Username: $generatedUsername", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),
            TextField(controller: favoriteAnimalController, decoration: InputDecoration(labelText: "Favorite Animal")),
            TextField(controller: favoriteColorController, decoration: InputDecoration(labelText: "Favorite Color")),
            TextField(controller: favoriteNumberController, decoration: InputDecoration(labelText: "Favorite One-Digit Number")),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  generatedPassword = generatePassword(
                    favoriteAnimalController.text.trim(),
                    favoriteColorController.text.trim(),
                    favoriteNumberController.text.trim(),
                  );
                });
              },
              child: Text("Generate Password"),
            ),
            Text("Generated Password: $generatedPassword", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextField(controller: confirmPasswordController, decoration: InputDecoration(labelText: "Confirm Password")),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : createStudentAccount,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
