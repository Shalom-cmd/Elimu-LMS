import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class CreateQuizPage extends StatefulWidget {
  final DocumentSnapshot? quiz;
  const CreateQuizPage({super.key, this.quiz});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final inAppTextController = TextEditingController();

  List<Map<String, dynamic>> questions = [];

  String? selectedSubject;
  DateTime? dueDate;
  TimeOfDay? dueTime;

  bool createInApp = false;
  bool isEditing = false;

  String? schoolDomain;
  String? grade;

  String fileName = '';
  Uint8List? fileBytes;
  String fileUrl = '';

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

    if (widget.quiz != null) {
      final data = widget.quiz!.data() as Map<String, dynamic>;
      isEditing = true;
      titleController.text = data['title'] ?? '';
      descriptionController.text = data['description'] ?? '';
      selectedSubject = data['subject'];
      createInApp = data['type'] == 'in-app';

      final Timestamp? timestamp = data['dueDate'];
      if (timestamp != null) {
        final dt = timestamp.toDate();
        dueDate = DateTime(dt.year, dt.month, dt.day);
        dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      inAppTextController.text = data['createdInAppText'] ?? '';
      fileUrl = data['fileUrl'] ?? '';

      final storedQuestions = data['questions'];
      if (storedQuestions != null && storedQuestions is List) {
        questions = List<Map<String, dynamic>>.from(storedQuestions);
      }
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

  void addNewQuestion() {
    setState(() {
      questions.add({
        'question': '',
        'options': List<String>.filled(4, ''),
        'correct': 0,
      });
    });
  }

  Future<String> uploadFileToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    final storageRef = FirebaseStorage.instance
        .ref('quizzes/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final uploadTask = await storageRef.putData(fileBytes!);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> submitQuiz() async {
    if (titleController.text.isEmpty ||
        selectedSubject == null ||
        dueDate == null ||
        dueTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Please complete all required fields.")),
      );
      return;
    }

    final dueDateTime = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );

    String downloadUrl = fileUrl;
    if (!createInApp) {
      if (fileBytes != null) {
        try {
          downloadUrl = await uploadFileToFirebase();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed to upload file: $e")),
          );
          return;
        }
      }
    }

    final quizDoc = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'subject': selectedSubject,
      'dueDate': dueDateTime,
      'type': createInApp ? "in-app" : "file",
      'createdInAppText': createInApp ? inAppTextController.text.trim() : "",
      'fileUrl': downloadUrl,
      'questions': createInApp ? questions : [],
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final quizRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection('quizzes');

    if (isEditing && widget.quiz != null) {
      await widget.quiz!.reference.update(quizDoc);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ Quiz updated!")));
    } else {
      await quizRef.add(quizDoc);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ Quiz posted!")));
    }

    Navigator.pop(context);
  }

  String formatDateTime() {
    if (dueDate == null || dueTime == null) return "Not selected";
    final date = DateFormat.yMd().format(dueDate!);
    final time = dueTime!.format(context);
    return "$date at $time";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🧠 Create Quiz")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📘 Quiz Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: InputDecoration(labelText: "Subject"),
              items: subjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (val) => setState(() => selectedSubject = val),
            ),
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description / Instructions"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Text("⏰ Due Date & Time", style: TextStyle(fontWeight: FontWeight.w600)),
            ListTile(
              title: Text("Due: ${formatDateTime()}"),
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
            const Divider(),

            Text("🖊️ Write Quiz In App"),
            SwitchListTile(
              title: Text("Enable In-App Quiz"),
              value: createInApp,
              onChanged: (val) => setState(() => createInApp = val),
            ),

            if (createInApp)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < questions.length; i++)
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Question ${i + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextField(
                              decoration: InputDecoration(labelText: "Question"),
                              onChanged: (val) => questions[i]['question'] = val,
                              controller: TextEditingController(text: questions[i]['question']),
                            ),
                            for (int j = 0; j < 4; j++)
                              ListTile(
                                title: TextField(
                                  decoration: InputDecoration(labelText: "Option ${j + 1}"),
                                  onChanged: (val) => questions[i]['options'][j] = val,
                                  controller: TextEditingController(text: questions[i]['options'][j]),
                                ),
                                leading: Radio<int>(
                                  value: j,
                                  groupValue: questions[i]['correct'],
                                  onChanged: (val) => setState(() {
                                    questions[i]['correct'] = val!;
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: addNewQuestion,
                    icon: Icon(Icons.add),
                    label: Text("Add Question"),
                  )
                ],
              ),

            if (!createInApp) ...[
              const SizedBox(height: 20),
              Text("📎 Or Pick a Quiz File"),
              ElevatedButton.icon(
                onPressed: pickFileWeb,
                icon: Icon(Icons.upload_file),
                label: Text("Pick File"),
              ),
              if (fileUrl.isNotEmpty && fileName.isEmpty)
                Text("✅ File already uploaded."),
              if (fileName.isNotEmpty)
                Text("Selected: $fileName", style: TextStyle(fontStyle: FontStyle.italic)),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitQuiz,
                icon: Icon(Icons.check),
                label: Text(isEditing ? "Update Quiz" : "Post Quiz"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
