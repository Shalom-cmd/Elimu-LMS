import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassRosterPage extends StatefulWidget {
  final String schoolDomain;

  const ClassRosterPage({super.key, required this.schoolDomain});

  @override
  State<ClassRosterPage> createState() => _ClassRosterPageState();
}

class _ClassRosterPageState extends State<ClassRosterPage> {
  late Future<List<Map<String, dynamic>>> teacherListFuture;
  late Future<List<Map<String, dynamic>>> studentListFuture;

  @override
  void initState() {
    super.initState();
    teacherListFuture = fetchUsers('teachers');
    studentListFuture = fetchUsers('students');
  }

  Future<List<Map<String, dynamic>>> fetchUsers(String collection) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolDomain)
        .collection(collection)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  final Map<String, String> readableLabels = {
    'uid': 'Unique ID',
    'fullName': 'Full Name',
    'firstName': 'First Name',
    'lastName': 'Last Name',
    'email': 'Email',
    'phoneNumber': 'Phone Number',
    'homeAddress': 'Home Address',
    'address': 'Address',
    'parentEmail': 'Parent Email',
    'parentPhoneNumber': 'Parent Phone',
    'emergencyContactName': 'Emergency Contact Name',
    'emergencyContactPhone': 'Emergency Contact Phone',
    'emergencyContactEmail': 'Emergency Contact Email',
    'gradeLevel': 'Grade Level',
    'grade': 'Grade',
    'username': 'Username',
  };

  Widget buildExpansionTile(String title, List<Map<String, dynamic>> users) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      children: users.map((user) {
        final name = user['fullName'] ?? 'Unknown';
        return ExpansionTile(
          title: Text(name),
          children: user.entries.map((entry) {
            final label = readableLabels[entry.key] ?? entry.key;
            final value = entry.value?.toString() ?? '';
            return ListTile(
              title: Text("$label: $value"),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🏫 School Roster")),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: Future.wait([teacherListFuture, studentListFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final teacherList = snapshot.data![0];
          final studentList = snapshot.data![1];

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              buildExpansionTile("👩‍🏫 Teachers", teacherList),
              SizedBox(height: 20),
              buildExpansionTile("🧒 Students", studentList),
            ],
          );
        },
      ),
    );
  }
}
