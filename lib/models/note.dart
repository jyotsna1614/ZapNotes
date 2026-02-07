class Note {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isLocked;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isLocked = false,
  });

  // Convert Note to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLocked': isLocked,
    };
  }

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isLocked: json['isLocked'] ?? false,
    );
  }

  // Create a copy of Note with some fields changed
  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isLocked,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}