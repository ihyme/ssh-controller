class SnippetModel {
  final String id;
  final String title;
  final String command;
  final String category;
  final String icon;
  final String description;
  final DateTime createdAt;

  SnippetModel({
    required this.id,
    required this.title,
    required this.command,
    this.category = 'Genel',
    this.icon = 'terminal',
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'command': command,
      'category': category,
      'icon': icon,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SnippetModel.fromMap(Map<String, dynamic> map) {
    return SnippetModel(
      id: map['id'] as String,
      title: map['title'] as String,
      command: map['command'] as String,
      category: (map['category'] as String?) ?? 'Genel',
      icon: (map['icon'] as String?) ?? 'terminal',
      description: (map['description'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
