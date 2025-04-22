import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAssignmentPage extends StatefulWidget {
  final DocumentSnapshot? assignment;
  const CreateAssignmentPage({Key? key, this.assignment}) : super(key: key);


  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final inAppTextController = TextEditingController();

  String fileName = '';
  Uint8List? fileBytes;
  String fileUrl = '';
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool createInApp = false;
  bool isEditing = false;

  String schoolDomain = '';
  String grade = '';
  String? selectedSubject;
  String? assignmentId;

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

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();

    if (widget.assignment != null) {
      final data = widget.assignment!.data() as Map<String, dynamic>;
      titleController.text = data['title'] ?? '';
      descriptionController.text = data['description'] ?? '';
      inAppTextController.text = data['createdInAppText'] ?? '';
      createInApp = data['type'] == 'in-app';

      final Timestamp? timestamp = data['dueDate'];
      if (timestamp != null) {
        final dt = timestamp.toDate();
        dueDate = DateTime(dt.year, dt.month, dt.day);
        dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      selectedSubject = data['subject'];
      if (!subjects.contains(selectedSubject)) {
        selectedSubject = null;
      }
      isEditing = true;
    }
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
        break;
      }
    }
  }

  void pickFileWeb() {
    final uploadInput = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file!);
      reader.onLoadEnd.listen((e) {
        setState(() {
          fileName = file.name;
          fileBytes = reader.result as Uint8List;
        });
      });
    });
  }


  Future<String> uploadFileToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final storageRef = FirebaseStorage.instance
        .ref('assignments/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final uploadTask = await storageRef.putData(fileBytes!);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> submitAssignment() async {
    if (titleController.text.trim().isEmpty || dueDate == null || dueTime == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in all required fields.")));
      return;
    }

    final dueDateTime = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );

    String downloadUrl = "";

    if (!createInApp) {
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📎 Please pick a file to upload.")));
        return;
      }

      try {
        downloadUrl = await uploadFileToFirebase();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to upload file: $e")));
        return;
      }
    }

    final doc = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'subject': selectedSubject,
      'dueDate': dueDateTime,
      'fileUrl': downloadUrl,
      'createdInAppText': createInApp ? inAppTextController.text.trim() : "",
      'type': createInApp ? "in-app" : "file",
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
    };

    if (isEditing && widget.assignment != null) {
      await widget.assignment!.reference.update(doc);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Assignment updated!")));
    } else {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDomain)
          .collection('classes')
          .doc(grade)
          .collection('assignments')
          .add(doc);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Assignment posted!")));
    }

    Navigator.pop(context);
  }


  String formatDateTime() {
    if (dueDate == null || dueTime == null) return "Not selected";
    final date = "${dueDate!.month}/${dueDate!.day}/${dueDate!.year}";
    final time = dueTime!.format(context);
    return "$date at $time";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📄 Create Assignment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📝 Assignment Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: InputDecoration(labelText: "📘 Subject"),
              items: subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description / Instructions"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),



            const SizedBox(height: 20),
            Text("⏰ Due Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ListTile(
              title: Text("📅 Due: ${formatDateTime()}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      dueDate = pickedDate;
                      dueTime = pickedTime;
                    });
                  }
                }
              },
            ),
            const Divider(height: 30),

            Text("🖊️ Write Assignment in App", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SwitchListTile(
              title: Text("Enable In-App Creation"),
              value: createInApp,
              onChanged: (val) => setState(() => createInApp = val),
            ),
            if (createInApp)
              TextField(
                controller: inAppTextController,
                decoration: InputDecoration(
                  hintText: "Write assignment content here...",
                  border: OutlineInputBorder(),
                ),
                minLines: 6,
                maxLines: null,
              ),

            const SizedBox(height: 24),
            if (!createInApp && kIsWeb) ...[
              Text("📎 Or Pick an Assignment File", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickFileWeb,
                icon: Icon(Icons.upload_file),
                label: Text("Pick File"),
              ),
              if (fileName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Selected: $fileName", style: TextStyle(fontStyle: FontStyle.italic)),
                ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text("Post Assignment"),
                onPressed: submitAssignment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
