import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  Future<void> registerSchool() async {
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

    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(emailAddressController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumberController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid 10-digit phone number')));
      return;
    }

    try {
      DateFormat('yyyy-MM-dd').parse(startDateController.text.trim());
      DateFormat('yyyy-MM-dd').parse(endDateController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid start/end dates (yyyy-MM-dd)')));
      return;
    }

    final schoolDomain = schoolDomainController.text.trim();
    final existingSchool = await FirebaseFirestore.instance.collection('schools').doc(schoolDomain).get();
    if (existingSchool.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This school domain is already registered')));
      return;
    }

    try {
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
        'logo': logoController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('School Registered Successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register School")),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(30),
          children: [
            _buildTextField("School Name", schoolNameController),
            _buildTextField("School Domain/ID", schoolDomainController),
            _buildTextField("School Type (Public/Private)", schoolTypeController),

            _buildSectionHeader("Location"),
            _buildTextField("City", cityController),
            _buildTextField("State", stateController),
            _buildTextField("Country", countryController),

            _buildSectionHeader("Contact Information"),
            _buildTextField("Phone Number", phoneNumberController),
            _buildTextField("Email Address", emailAddressController),
            _buildTextField("Website URL", websiteController),

            _buildTextField("Grades Offered (e.g., K-5, 6-8, 9-12)", gradesOfferedController),
            _buildTextField("School Administrator Name", adminNameController),

            _buildSectionHeader("Academic Calendar"),
            _buildTextField("Start Date (yyyy-MM-dd)", startDateController),
            _buildTextField("End Date (yyyy-MM-dd)", endDateController),

            _buildTextField("School Description", schoolDescriptionController),
            _buildTextField("School Logo (Optional)", logoController),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerSchool,
              child: Text("Register School"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
