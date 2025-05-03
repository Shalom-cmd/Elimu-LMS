import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassActivityOverviewPage extends StatefulWidget {
  final String schoolDomain;

  const ClassActivityOverviewPage({super.key, required this.schoolDomain});

  @override
  State<ClassActivityOverviewPage> createState() => _ClassActivityOverviewPageState();
}

class _ClassActivityOverviewPageState extends State<ClassActivityOverviewPage> {
  late Future<List<Map<String, dynamic>>> classSummaries;

  @override
  void initState() {
    super.initState();
    classSummaries = fetchClassSummaries();
  }

  Future<List<Map<String, dynamic>>> fetchClassSummaries() async {
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolDomain)
        .collection('classes')
        .get();

    List<Map<String, dynamic>> summaries = [];

    for (var classDoc in classesSnapshot.docs) {
      final grade = classDoc.id;

      // Get teachers
      final teachersSnapshot = await classDoc.reference.collection('teachers').get();
      final teacherNames = teachersSnapshot.docs
          .map((doc) => doc.data()['fullName'] ?? 'Unknown')
          .toList();

      // Get students
      final studentsSnapshot = await classDoc.reference.collection('students').get();
      final studentNames = studentsSnapshot.docs
          .map((doc) => doc.data()['fullName'] ?? 'Unnamed')
          .toList();

      // Get assignments
      final assignmentsSnapshot = await classDoc.reference.collection('assignments').get();
      final assignments = await Future.wait(assignmentsSnapshot.docs.map((assignmentDoc) async {
        final data = assignmentDoc.data();
        final submissionsSnapshot = await assignmentDoc.reference.collection('submissions').get();

        return {
          'title': data['title'] ?? 'Untitled',
          'dueDate': (data['dueDate'] as Timestamp?)?.toDate(),
          'type': data['type'] ?? 'unknown',
          'submissions': submissionsSnapshot.size,
        };
      }).toList());

      // Get quizzes
      final quizzesSnapshot = await classDoc.reference.collection('quizzes').get();
      final quizzes = await Future.wait(quizzesSnapshot.docs.map((quizDoc) async {
        final data = quizDoc.data();
        final submissionsSnapshot = await quizDoc.reference.collection('submissions').get();

        return {
          'title': data['title'] ?? 'Untitled',
          'dueDate': (data['dueDate'] as Timestamp?)?.toDate(),
          'submissions': submissionsSnapshot.size,
        };
      }).toList());

      summaries.add({
        'grade': grade,
        'teachers': teacherNames,
        'students': studentNames,
        'assignments': assignments,
        'quizzes': quizzes,
      });
    }

    return summaries;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Class Activity Overview")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: classSummaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("❌ Error loading data: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No class data found."));
          }

          final classData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classData.length,
            itemBuilder: (context, index) {
              final classInfo = classData[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🎓 ${classInfo['grade']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("👩‍🏫 Teachers: ${classInfo['teachers'].join(', ')}"),
                      ExpansionTile(
                        title: Text("🧒 Students (${(classInfo['students'] as List).length})"),
                        children: (classInfo['students'] as List)
                            .map<Widget>((name) => ListTile(
                                  title: Text(name),
                                  dense: true,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text("📌 Assignments:", style: TextStyle(fontWeight: FontWeight.w600)),
                      ...(classInfo['assignments'] as List).map<Widget>((a) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a['title']),
                          subtitle: Text("Type: ${a['type']} | Due: ${formatDate(a['dueDate'])} | Submissions: ${a['submissions']}",),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: Text("🧠 Quizzes (${(classInfo['quizzes'] as List).length})"),
                        children: (classInfo['quizzes'] as List).map<Widget>((q) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 16, right: 16),
                            title: Text(q['title']),
                            subtitle: Text("Due: ${formatDate(q['dueDate'])} | Submissions: ${q['submissions']}"),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
