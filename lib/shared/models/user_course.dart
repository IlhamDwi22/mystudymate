class UserCourse {
  final String id;
  final String userId;
  final String courseName;
  final DateTime createdAt;

  UserCourse({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.createdAt,
  });

  UserCourse copyWith({
    String? id,
    String? userId,
    String? courseName,
    DateTime? createdAt,
  }) {
    return UserCourse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserCourse.fromJson(Map<String, dynamic> json) {
    return UserCourse(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseName: json['course_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'course_name': courseName,
    };
  }
}
