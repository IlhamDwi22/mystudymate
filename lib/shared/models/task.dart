class Task {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String status; // 'todo', 'doing', 'done'
  final String? assigneeId;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.deadline,
    required this.status,
    this.assigneeId,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    DateTime? deadline,
    String? status,
    String? assigneeId,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: json['status'] as String? ?? 'todo',
      assigneeId: json['assignee_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspace_id': workspaceId,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'assignee_id': assigneeId,
    };
  }
}
