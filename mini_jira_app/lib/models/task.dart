class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.priority = 'Medium',
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'To Do',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['due_date'],
    );
  }
}