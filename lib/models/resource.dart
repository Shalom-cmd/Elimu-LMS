class Resource {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String? fileUrl;
  final String? link;
  final String createdAt;

  Resource({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    this.fileUrl,
    this.link,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'link': link,
      'createdAt': createdAt,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'],
      subject: map['subject'],
      title: map['title'],
      description: map['description'],
      fileUrl: map['fileUrl'],
      link: map['link'],
      createdAt: map['createdAt'],
    );
  }
}
