import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../pdf_viewer_page.dart';
import '../../helpers/hive_helper.dart';
import '../../models/resource.dart';
import 'package:open_file/open_file.dart';

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
  List<Resource> resources = [];

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    final box = Hive.box('profileBox');

    if (user == null) {
      final cached = box.get('studentProfile');
      if (cached != null) {
        setState(() {
          studentName = cached['fullName'];
          grade = cached['grade'];
          schoolDomain = cached['schoolDomain'];
        });
        fetchResources();
      }
      return;
    }

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
    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('resources')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Resource> fetched = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        final fileUrl = data.containsKey('fileUrl') ? data['fileUrl'] : null;
        final link = data.containsKey('link') ? data['link'] : null;

        final resource = Resource(
          id: doc.id,
          subject: data['subject'] ?? 'General',
          title: data['title'] ?? 'No Title',
          description: data['description'] ?? '',
          fileUrl: fileUrl,
          link: link,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? '',
        );

        fetched.add(resource);

        if (fileUrl != null && fileUrl.isNotEmpty) {
          await downloadResourceFile(resource.id, fileUrl);
        }
      }

      await saveResourcesToHive(fetched);

      setState(() {
        resources = fetched;
        isLoading = false;
      });
    } catch (e) {
      print('🔥 Firestore failed, loading resources from Hive instead: $e');
      final offlineResources = loadResourcesFromHive();
      setState(() {
        resources = offlineResources;
        isLoading = false;
      });
    }
  }

  Future<void> downloadResourceFile(String resourceId, String fileUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/resource_$resourceId.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        print('📄 Resource $resourceId already cached.');
        return;
      }

      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Cached resource $resourceId');
      } else {
        print('❌ Failed to download resource file: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error downloading resource: $e');
    }
  }

    Future<void> openResourceFile(Resource resource) async {
    if (resource.fileUrl == null || resource.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file URL available.')),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/resource_${resource.id}.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        print('📄 Opening cached file for resource ${resource.id}');
        await OpenFile.open(file.path);
      } else {
        print('⬇️ Downloading resource file for ${resource.id}: ${resource.fileUrl}');
        final response = await http.get(Uri.parse(resource.fileUrl!));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('✅ Resource file saved locally: ${file.path}');
          await OpenFile.open(file.path);
        } else {
          print('❌ Failed to download file. Status: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not download resource file.')),
          );
        }
      }
    } catch (e) {
      print('❌ Error opening resource: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file.')),
      );
    }
  }

  String formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return DateFormat('MMMM d, yyyy').format(date);
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
                    final subject = resource.subject;
                    final title = resource.title;
                    final description = resource.description;
                    final fileUrl = resource.fileUrl;
                    final linkUrl = resource.link;
                    final date = formatDate(resource.createdAt);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📘 $subject", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("📄 $title", style: const TextStyle(fontSize: 18)),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text("📝 $description"),
                              ),
                            const SizedBox(height: 10),
                            if (fileUrl != null && fileUrl.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => openResourceFile(resource),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("Open File"),
                            ),
                            if (linkUrl != null && linkUrl.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(linkUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not open link.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.link),
                                label: const Text("Open Link"),
                              ),
                            const SizedBox(height: 4),
                            if (date.isNotEmpty)
                              Text("Posted on $date", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
