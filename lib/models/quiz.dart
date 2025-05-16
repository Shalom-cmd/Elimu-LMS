class Quiz {
  final String id;
  final String title;
  final String subject;
  final String type;
  final String? fileUrl;
  final String? createdInAppText;
  final List<Map<String, dynamic>> questions;
  final String dueDate;

  Quiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    this.fileUrl,
    this.createdInAppText,
    required this.questions,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'type': type,
      'fileUrl': fileUrl,
      'createdInAppText': createdInAppText,
      'questions': questions,
      'dueDate': dueDate,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Quiz',
      subject: map['subject'] ?? 'Uncategorized',
      type: map['type'] ?? 'file',
      fileUrl: map['fileUrl'],
      createdInAppText: map['createdInAppText'],
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) => Map<String, dynamic>.from(q))
              .toList() ??
          [],
      dueDate: map['dueDate'] ?? '',
    );
  }
}
