import 'package:hive/hive.dart';
import '../models/assignment.dart';
import '../models/quiz.dart';
import '../models/resource.dart';
import 'package:hive/hive.dart';

Future<void> saveAssignmentsToHive(List<Assignment> assignments) async {
  final box = Hive.box('assignmentsBox');
  final data = assignments.map((a) => a.toMap()).toList();
  await box.put('cachedAssignments', data);
}

List<Assignment> loadAssignmentsFromHive() {
  final box = Hive.box('assignmentsBox');
  final List cached = box.get('cachedAssignments', defaultValue: []);
  return cached.map((map) => Assignment.fromMap(Map<String, dynamic>.from(map))).toList();
}

Future<void> saveQuizzesToHive(List<Quiz> quizzes) async {
  final box = await Hive.openBox('quizzesBox');
  await box.put('cachedQuizzes', quizzes.map((q) => q.toMap()).toList());
}

List<Quiz> loadQuizzesFromHive() {
  final box = Hive.box('quizzesBox');
  final List cached = box.get('cachedQuizzes', defaultValue: []);
  return cached.map((map) => Quiz.fromMap(Map<String, dynamic>.from(map))).toList();
}

Future<void> saveResourcesToHive(List<Resource> resources) async {
  final box = await Hive.openBox('resourcesBox');
  final List<Map<String, dynamic>> resourceMaps = resources.map((r) => r.toMap()).toList();
  await box.put('resources', resourceMaps);
}

List<Resource> loadResourcesFromHive() {
  final box = Hive.box('resourcesBox');
  final resourceMaps = box.get('resources', defaultValue: []) as List<dynamic>;

  return resourceMaps.map((map) => Resource.fromMap(Map<String, dynamic>.from(map))).toList();
}
