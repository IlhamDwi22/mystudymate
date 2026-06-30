class UserProfile {
  final String id;
  final String fullName;
  final String major;
  final int semester;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.major,
    required this.semester,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? major,
    int? semester,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      major: major ?? this.major,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
