import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_Assignment_page.dart';

class ViewAssignmentsPage extends StatefulWidget {
  const ViewAssignmentsPage({Key? key}) : super(key: key);

  @override
  State<ViewAssignmentsPage> createState() => _ViewAssignmentsPageState();
}

class _ViewAssignmentsPageState extends State<ViewAssignmentsPage> {
  String schoolDomain = '';
  String grade = '';
  bool isLoading = true;
  Map<String, List<DocumentSnapshot>> groupedAssignments = {};

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('teachers')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        schoolDomain = school.id;
        grade = doc['gradeLevel'];
        fetchAssignments();
        break;
      }
    }
  }

  Future<void> fetchAssignments() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('assignments')
        .orderBy('dueDate')
        .get();

    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (var doc in snap.docs) {
      String subject = doc.data().toString().contains('subject')
          ? doc['subject']
          : 'Uncategorized';

      grouped.putIfAbsent(subject, () => []).add(doc);
    }

    setState(() {
      groupedAssignments = grouped;
      isLoading = false;
    });
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    return DateFormat('MMMM dd, yyyy – hh:mm a').format(timestamp.toDate());
  }

  void openFileInNewTab(String url) {
    html.window.open(url, "_blank");
  }

  void openEditScreen(DocumentSnapshot assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛠️ Editing: ${assignment['title']}')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAssignmentPage(assignment: assignment),
      ),
    );
  }
  void deleteAssignment(DocumentSnapshot assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("🗑️ Confirm Delete"),
        content: Text("Are you sure you want to delete '${assignment['title']}'?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await assignment.reference.delete();

      setState(() {
        final subject = assignment.data().toString().contains('subject')
            ? assignment['subject']
            : 'Uncategorized';

        groupedAssignments[subject]?.removeWhere((doc) => doc.id == assignment.id);

        // Optional: Clean up empty subjects
        if (groupedAssignments[subject]?.isEmpty ?? false) {
          groupedAssignments.remove(subject);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Assignment deleted.")),
      );
    }
  }

  Color getSubjectColor(String subject) {
    final index = subject.hashCode % Colors.primaries.length;
    return Colors.primaries[index].shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📚 View Assignments")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedAssignments.isEmpty
              ? Center(child: Text("No assignments yet."))
              : ListView(
                  padding: EdgeInsets.all(12),
                  children: groupedAssignments.entries.map((entry) {
                    final subject = entry.key;
                    final assignments = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: getSubjectColor(subject),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...assignments.map((assignment) {
                          final title = assignment['title'];
                          final type = assignment['type'];
                          final dueDate = formatDate(assignment['dueDate']);
                          final description = assignment['description'] ?? '';
                          final fileUrl = assignment['fileUrl'];
                          final inAppText = assignment.data().toString().contains('createdInAppText')
                              ? assignment['createdInAppText']
                              : null;

                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text("📅 Due: $dueDate",
                                      style: TextStyle(color: Colors.grey[700])),
                                  SizedBox(height: 10),
                                  if (type == "file" && fileUrl != null)
                                    ElevatedButton.icon(
                                      onPressed: () => openFileInNewTab(fileUrl),
                                      icon: Icon(Icons.open_in_new),
                                      label: Text("Open File"),
                                    ),
                                  if (type == "in-app" && inAppText != null)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      margin: EdgeInsets.only(top: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(inAppText),
                                    ),
                                  if (description.isNotEmpty) ...[
                                    SizedBox(height: 10),
                                    Text("📝 Notes: $description"),
                                  ],
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => openEditScreen(assignment),
                                        icon: Icon(Icons.edit),
                                        label: Text("Edit"),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => deleteAssignment(assignment),
                                        icon: Icon(Icons.delete_forever),
                                        label: Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
