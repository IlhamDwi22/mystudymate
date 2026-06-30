class RepositoryFile {
  final String id;
  final String userId;
  final String title;
  final String courseName;
  final String filePath;
  final DateTime uploadedAt;
  final String? uploaderName;

  RepositoryFile({
    required this.id,
    required this.userId,
    required this.title,
    required this.courseName,
    required this.filePath,
    required this.uploadedAt,
    this.uploaderName,
  });

  RepositoryFile copyWith({
    String? id,
    String? userId,
    String? title,
    String? courseName,
    String? filePath,
    DateTime? uploadedAt,
    String? uploaderName,
  }) {
    return RepositoryFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      courseName: courseName ?? this.courseName,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploaderName: uploaderName ?? this.uploaderName,
    );
  }

  factory RepositoryFile.fromJson(Map<String, dynamic> json) {
    // Check if profiles join is present
    String? uploader;
    if (json['profiles'] != null) {
      final profile = json['profiles'] as Map<String, dynamic>;
      uploader = profile['full_name'] as String?;
    }

    return RepositoryFile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      courseName: json['course_name'] as String,
      filePath: json['file_path'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      uploaderName: uploader,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'course_name': courseName,
      'file_path': filePath,
      'user_id': userId,
    };
  }
}
