class Assignment {
  final String id;
  final String title;
  final String subject;
  final String dueDate;
  final String? fileUrl;
  final String? description;
  final String? type;
  final String? createdInAppText; 

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.fileUrl,
    this.description,
    this.type,
    this.createdInAppText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate,
      'fileUrl': fileUrl,
      'description': description,
      'type': type,
      'createdInAppText': createdInAppText,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      dueDate: map['dueDate'],
      fileUrl: map['fileUrl'],
      description: map['description'],
      type: map['type'],
      createdInAppText: map['createdInAppText'],
    );
  }
}
