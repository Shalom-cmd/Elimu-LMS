import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentResourcesPage extends StatefulWidget {
  const StudentResourcesPage({Key? key}) : super(key: key);

  @override
  State<StudentResourcesPage> createState() => _StudentResourcesPageState();
}

class _StudentResourcesPageState extends State<StudentResourcesPage> {
  String studentName = '';
  String schoolDomain = '';
  String grade = '';
  bool isLoading = true;
  List<DocumentSnapshot> resources = [];

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schools = await FirebaseFirestore.instance.collection('schools').get();
    for (var school in schools.docs) {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          studentName = doc['fullName'];
          grade = doc['grade'];
          schoolDomain = school.id;
        });
        fetchResources();
        break;
      }
    }
  }

  Future<void> fetchResources() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      resources = snapshot.docs;
      isLoading = false;
    });
  }

  void openFile(String url) {
    html.window.open(url, "_blank");
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📚 Class Resources")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : resources.isEmpty
              ? const Center(child: Text("No resources posted yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final resource = resources[index];
                    final subject = resource['subject'] ?? 'General';
                    final title = resource['title'] ?? 'No Title';
                    final description = resource['description'] ?? '';
                    final fileUrl = resource.data().toString().contains('fileUrl') ? resource['fileUrl'] : null;
                    final linkUrl = resource.data().toString().contains('link') ? resource['link'] : null;
                    final date = formatDate(resource['createdAt']);


                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📘 $subject",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("📄 $title", style: const TextStyle(fontSize: 18)),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text("📝 $description"),
                              ),
                            const SizedBox(height: 10),
                            if (fileUrl != null && fileUrl != "")
                              ElevatedButton.icon(
                                onPressed: () => openFile(fileUrl),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text("Open File"),
                              ),
                            if (linkUrl != null && linkUrl != "")
                              ElevatedButton.icon(
                                onPressed: () => openFile(linkUrl),
                                icon: const Icon(Icons.link),
                                label: const Text("Open Link"),
                              ),
                            const SizedBox(height: 4),
                            Text("Posted on $date",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
