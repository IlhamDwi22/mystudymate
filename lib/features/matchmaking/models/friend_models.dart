import '../../../shared/models/user_profile.dart';

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderMajor;
  final int senderSemester;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderMajor,
    required this.senderSemester,
    required this.createdAt,
  });

  factory FriendRequest.fromRpc(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['request_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['full_name'] as String? ?? 'Unknown',
      senderMajor: json['major'] as String? ?? '',
      senderSemester: json['semester'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FriendProfile {
  final String id;
  final String fullName;
  final String major;
  final int semester;

  FriendProfile({
    required this.id,
    required this.fullName,
    required this.major,
    required this.semester,
  });

  factory FriendProfile.fromRpc(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['friend_id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown',
      major: json['major'] as String? ?? '',
      semester: json['semester'] as int? ?? 1,
    );
  }

  /// Convert to UserProfile for workspace invitation compatibility
  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      fullName: fullName,
      major: major,
      semester: semester,
      createdAt: DateTime.now(),
    );
  }
}
