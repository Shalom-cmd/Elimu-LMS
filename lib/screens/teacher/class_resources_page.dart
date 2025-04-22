import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        fetchResources(); // Load resources after we get domain/grade
        break;
      }
    }
  }

  void pickFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file!);
      reader.onLoadEnd.listen((event) {
        setState(() {
          fileName = file.name;
          fileBytes = reader.result as Uint8List;
        });
      });
    });
  }

  Future<void> uploadResource() async {
    if (selectedSubject == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in the required fields.")));
      return;
    }

    String? fileUrl;

    if (fileBytes != null && fileName != null) {
      final ref = FirebaseStorage.instance
          .ref('resources/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      await ref.putData(fileBytes!);
      fileUrl = await ref.getDownloadURL();
    }

    final data = {
      'subject': selectedSubject,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'link': _linkController.text.trim(),
      'fileUrl': fileUrl,
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
                          onPressed: () => html.window.open(res['link'], '_blank'),
                        ),
                      if ((res['fileUrl'] ?? "").isNotEmpty)
                        TextButton.icon(
                          icon: Icon(Icons.picture_as_pdf),
                          label: Text("Open File"),
                          onPressed: () => html.window.open(res['fileUrl'], '_blank'),
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
