import 'dart:io'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pdf_viewer_page.dart'; 


class ClassResourcesPage extends StatefulWidget {
  const ClassResourcesPage({Key? key}) : super(key: key);

  @override
  State<ClassResourcesPage> createState() => _ClassResourcesPageState();
}

class _ClassResourcesPageState extends State<ClassResourcesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();

  String schoolDomain = '';
  String grade = '';
  String? selectedSubject;
  String? fileName;
  Uint8List? fileBytes;

  final List<String> subjects = [
    'English Language Arts',
    'Mathematics',
    'Science',
    'History-Social Science',
    'Visual and Performing Arts',
    'Physical Education',
    'Health',
    'World Languages',
  ];

  final List<Map<String, dynamic>> uploadedResources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTeacherInfo();
  }

  Future<void> fetchTeacherInfo() async {
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
        setState(() {
          schoolDomain = school.id;
          grade = doc['gradeLevel'];
        });
        fetchResources(); 
        break;
      }
    }
  }
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        fileBytes = result.files.single.bytes!;
        fileName = result.files.single.name;
      });
    }
  }

  Future<String> uploadFileToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final storageRef = FirebaseStorage.instance
        .ref('resources/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final uploadTask = await storageRef.putData(fileBytes!);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  Future<void> uploadResource() async {
    if (selectedSubject == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in the required fields.")));
      return;
    }

    String? uploadedFileUrl;

    if (fileBytes != null && fileName != null) {
      try {
        uploadedFileUrl = await uploadFileToFirebase();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ File upload failed: $e")));
        return; 
      }
    }

    final data = {
      'subject': selectedSubject,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'link': _linkController.text.trim(),
      'fileUrl': uploadedFileUrl, // use uploaded file URL
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('resources')
        .add(data);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Resource uploaded!")));

    _titleController.clear();
    _descriptionController.clear();
    _linkController.clear();
    fileBytes = null;
    fileName = null;

    fetchResources();
  }


  void fetchResources() async {
    if (schoolDomain.isEmpty || grade.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      uploadedResources.clear();
      uploadedResources.addAll(snapshot.docs.map((doc) => doc.data()));
    });
  }

  Color getSubjectColor(String subject) {
    final index = subject.hashCode % Colors.primaries.length;
    return Colors.primaries[index].shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📚 Class Resources"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Create Resource"),
            Tab(text: "View Resources"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // CREATE RESOURCE TAB
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📘 Subject"),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  items: subjects.map((subject) {
                    return DropdownMenuItem(value: subject, child: Text(subject));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: "Optional Description", border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                Text("🔗 YouTube or External Link"),
                TextField(
                  controller: _linkController,
                  decoration: InputDecoration(hintText: "Paste link here", border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload File"),
                  onPressed: pickFile,
                ),
                if (fileName != null) Text("📎 Selected: $fileName"),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text("Save Resource"),
                  onPressed: uploadResource,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                )
              ],
            ),
          ),

          // VIEW RESOURCES TAB
          ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: uploadedResources.length,
            itemBuilder: (context, index) {
              final res = uploadedResources[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                color: getSubjectColor(res['subject'] ?? ''),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📘 ${res['subject']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("📄 ${res['title']}"),
                      if ((res['description'] ?? "").isNotEmpty) Text("📝 ${res['description']}"),
                      if ((res['link'] ?? "").isNotEmpty)
                        TextButton.icon(
                          icon: Icon(Icons.link),
                          label: Text("Open Link"),
                          onPressed: () => openFile(res['link'])
                        ),
                      if ((res['fileUrl'] ?? "").isNotEmpty)
                        TextButton.icon(
                          icon: Icon(Icons.picture_as_pdf),
                          label: Text("Open File"),
                          onPressed: () => openFile(res['fileUrl'])
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
