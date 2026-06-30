class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final int memberCount;
  final int activeTaskCount;

  Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.memberCount = 0,
    this.activeTaskCount = 0,
  });

  Workspace copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    int? memberCount,
    int? activeTaskCount,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      activeTaskCount: activeTaskCount ?? this.activeTaskCount,
    );
  }

  factory Workspace.fromJson(Map<String, dynamic> json, {int memberCount = 0, int activeTaskCount = 0}) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: memberCount,
      activeTaskCount: activeTaskCount,
    );
  }
}
