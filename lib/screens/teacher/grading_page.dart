import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GradingPage extends StatefulWidget {
  const GradingPage({Key? key}) : super(key: key);

  @override
  State<GradingPage> createState() => _GradingPageState();
}

class _GradingPageState extends State<GradingPage> {
  String schoolDomain = '';
  String grade = '';
  bool isLoading = true;
  bool gradingAssignments = true;
  String? selectedDocId;

  List<DocumentSnapshot> assignments = [];
  List<DocumentSnapshot> quizzes = [];
  Map<String, List<DocumentSnapshot>> submissions = {};

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
  }
  Future<void> openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file.')),
      );
    }
  }
  Future<void> fetchTeacherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final schools = await FirebaseFirestore.instance.collection('schools').get();

    for (var school in schools.docs) {
      final teacher = await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('teachers')
          .doc(user!.uid)
          .get();

      if (teacher.exists) {
        schoolDomain = school.id;
        grade = teacher['gradeLevel'];
        fetchDocs();
        break;
      }
    }
  }

  Future<void> fetchDocs() async {
    setState(() => isLoading = true);
    final collection = gradingAssignments ? 'assignments' : 'quizzes';
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection(collection)
        .orderBy('dueDate')
        .get();

    setState(() {
      if (gradingAssignments) {
        assignments = snap.docs;
      } else {
        quizzes = snap.docs;
      }
      isLoading = false;
    });
  }

  Future<void> fetchSubmissions(String docId) async {
    setState(() {
      isLoading = true;
      selectedDocId = docId;
    });

    final type = gradingAssignments ? 'assignments' : 'quizzes';
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection(type)
        .doc(docId)
        .collection('submissions')
        .get();

    setState(() {
      submissions[docId] = snap.docs;
      isLoading = false;
    });
  }

  Future<void> gradeSubmission(String docId, String studentId, String gradeText) async {
    final type = gradingAssignments ? 'assignments' : 'quizzes';
    final ref = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDomain)
        .collection('classes')
        .doc(grade)
        .collection(type)
        .doc(docId)
        .collection('submissions')
        .doc(studentId);

    await ref.update({'grade': gradeText});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Grade submitted.")));
    fetchSubmissions(docId);
  }

  @override
  Widget build(BuildContext context) {
    final items = gradingAssignments ? assignments : quizzes;

    return Scaffold(
      appBar: AppBar(
        title: Text(gradingAssignments ? "📝 Grade Assignments" : "🧠 Grade Quizzes"),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: gradingAssignments ? 'assignments' : 'quizzes',
              items: const [
                DropdownMenuItem(value: 'assignments', child: Text("📝 Assignments")),
                DropdownMenuItem(value: 'quizzes', child: Text("🧠 Quizzes")),
              ],
              onChanged: (val) {
                setState(() {
                  gradingAssignments = val == 'assignments';
                  selectedDocId = null;
                });
                fetchDocs();
              },
            ),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : selectedDocId == null
              ? ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final title = doc['title'];
                    return Card(
                      child: ListTile(
                        title: Text(title),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => fetchSubmissions(doc.id),
                      ),
                    );
                  },
                )
              : Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.arrow_back),
                      title: Text("Back to ${gradingAssignments ? 'Assignments' : 'Quizzes'}"),
                      onTap: () => setState(() => selectedDocId = null),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          Text("Ungraded", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ...submissions[selectedDocId]!
                              .where((doc) =>
                                !((doc.data() as Map)['grade']?.toString().trim().isNotEmpty ?? false)
                              )
                              .map((sub) => buildSubmissionCard(sub)),
                          SizedBox(height: 20),
                          Text("Graded", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ...submissions[selectedDocId]!
                              .where((doc) =>
                                ((doc.data() as Map)['grade']?.toString().trim().isNotEmpty ?? false)
                              )
                              .map((sub) => buildSubmissionCard(sub)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget buildSubmissionCard(DocumentSnapshot sub) {
    final data = sub.data() as Map<String, dynamic>;
    final name = data['studentName'] ?? '';
    final fileUrl = data['fileUrl'];
    final gradeValue = data['grade'] ?? '';

    final controller = TextEditingController(text: gradeValue);

    final String text;
    if (gradingAssignments) {
      text = data['textAnswer'] ?? '';
    } else {
      final quizDoc = quizzes.firstWhere((doc) => doc.id == selectedDocId);
      final quizData = quizDoc.data() as Map<String, dynamic>;
      final List questions = quizData['questions'] ?? [];
      text = List.generate(questions.length, (i) {
        final q = questions[i]['question'] ?? 'Untitled';
        final answer = data['answers']?[i.toString()] ?? 'No answer';
        return "Q${i + 1}: $q\n📝 Answer: $answer";
      }).join('\n\n');
    }


    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 $name", style: TextStyle(fontWeight: FontWeight.bold)),
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("📄 $text"),
              ),
            if (fileUrl != null)
              TextButton.icon(
                onPressed: () => openFile(fileUrl),
                icon: Icon(Icons.open_in_new),
                label: Text("Open File"),
              ),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: "Grade (e.g. A, B+, 95%)"),
              onSubmitted: (val) => gradeSubmission(selectedDocId!, sub.id, val),
            ),
            ElevatedButton(
              onPressed: () => gradeSubmission(selectedDocId!, sub.id, controller.text),
              child: Text("Submit Grade"),
            ),
          ],
        ),
      ),
    );
  }
}
