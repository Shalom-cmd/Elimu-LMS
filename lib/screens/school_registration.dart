import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
//remove unnecessary fields eg start date, end date
class SchoolRegistrationPage extends StatefulWidget {
  const SchoolRegistrationPage({Key? key}) : super(key: key);

  @override
  _SchoolRegistrationPageState createState() => _SchoolRegistrationPageState();
}

class _SchoolRegistrationPageState extends State<SchoolRegistrationPage> {
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolDomainController = TextEditingController();
  final TextEditingController schoolTypeController = TextEditingController(); 
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController gradesOfferedController = TextEditingController();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController schoolDescriptionController = TextEditingController();
  final TextEditingController logoController = TextEditingController();

  // Register the school in Firestore
  Future<void> registerSchool() async {
    // Input Validation
    if (schoolNameController.text.trim().isEmpty ||
        schoolDomainController.text.trim().isEmpty ||
        schoolTypeController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        stateController.text.trim().isEmpty ||
        countryController.text.trim().isEmpty ||
        phoneNumberController.text.trim().isEmpty ||
        emailAddressController.text.trim().isEmpty ||
        gradesOfferedController.text.trim().isEmpty ||
        adminNameController.text.trim().isEmpty ||
        startDateController.text.trim().isEmpty ||
        endDateController.text.trim().isEmpty ||
        schoolDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }

    // Email validation
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(emailAddressController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    // Phone number validation (basic check)
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumberController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid 10-digit phone number')));
      return;
    }

    // Date validation (simple format check)
    try {
      DateFormat('yyyy-MM-dd').parse(startDateController.text.trim());
      DateFormat('yyyy-MM-dd').parse(endDateController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter valid start and end dates (yyyy-MM-dd)')));
      return;
    }

    // Check if the school domain already exists
    final schoolDomain = schoolDomainController.text.trim();
    final existingSchool = await FirebaseFirestore.instance.collection('schools').doc(schoolDomain).get();
    if (existingSchool.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This school domain is already registered')));
      return;
    }

    try {
      // Register the school document in Firestore using the unique school domain
      await FirebaseFirestore.instance.collection('schools').doc(schoolDomain).set({
        'schoolName': schoolNameController.text.trim(),
        'schoolDomain': schoolDomain,
        'schoolType': schoolTypeController.text.trim(),
        'location': {
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'country': countryController.text.trim(),
        },
        'contactInfo': {
          'phoneNumber': phoneNumberController.text.trim(),
          'emailAddress': emailAddressController.text.trim(),
          'website': websiteController.text.trim(),
        },
        'gradesOffered': gradesOfferedController.text.trim(),
        'adminName': adminNameController.text.trim(),
        'academicCalendar': {
          'startDate': startDateController.text.trim(),
          'endDate': endDateController.text.trim(),
        },
        'schoolDescription': schoolDescriptionController.text.trim(),
        'logo': logoController.text.trim(), // If logo is uploaded
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('School Registered Successfully!')));

      // After registration, navigate back to the previous screen
      Navigator.pop(context); // Or Navigator.pushReplacement(...) to navigate to another page

    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register School")),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: ListView(
          children: [
            // School Name input
            TextField(
              controller: schoolNameController,
              decoration: InputDecoration(labelText: "School Name"),
            ),
            SizedBox(height: 20),

            // School Domain input (e.g., chicoelementary.edu)
            TextField(
              controller: schoolDomainController,
              decoration: InputDecoration(labelText: "School Domain/ID"),
            ),
            SizedBox(height: 20),

            // School Type input (Public or Private)
            TextField(
              controller: schoolTypeController,
              decoration: InputDecoration(labelText: "School Type (Public/Private)"),
            ),
            SizedBox(height: 20),

            // Location inputs
            Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: cityController,
              decoration: InputDecoration(labelText: "City"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: stateController,
              decoration: InputDecoration(labelText: "State"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: countryController,
              decoration: InputDecoration(labelText: "Country"),
            ),
            SizedBox(height: 20),

            // Contact Information
            Text("Contact Information", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: "Phone Number"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: emailAddressController,
              decoration: InputDecoration(labelText: "Email Address"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: websiteController,
              decoration: InputDecoration(labelText: "Website URL"),
            ),
            SizedBox(height: 20),

            // Grades Offered
            TextField(
              controller: gradesOfferedController,
              decoration: InputDecoration(labelText: "Grades Offered (e.g., K-5, 6-8, 9-12)"),
            ),
            SizedBox(height: 20),

            // School Administrator Name
            TextField(
              controller: adminNameController,
              decoration: InputDecoration(labelText: "School Administrator Name"),
            ),
            SizedBox(height: 20),

            // Academic Calendar
            Text("Academic Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: startDateController,
              decoration: InputDecoration(labelText: "Start Date (yyyy-MM-dd)"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: endDateController,
              decoration: InputDecoration(labelText: "End Date (yyyy-MM-dd)"),
            ),
            SizedBox(height: 20),

            // School Description
            TextField(
              controller: schoolDescriptionController,
              decoration: InputDecoration(labelText: "School Description"),
            ),
            SizedBox(height: 20),

            // School Logo (Optional, can upload)
            TextField(
              controller: logoController,
              decoration: InputDecoration(labelText: "School Logo (Optional)"),
            ),
            SizedBox(height: 20),

            // Register Button
            ElevatedButton(
              onPressed: registerSchool,
              child: Text("Register School"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
