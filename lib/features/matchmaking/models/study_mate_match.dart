import '../../../shared/models/user_profile.dart';

class StudyMateMatch {
  final UserProfile profile;
  final List<String> sharedCourses;
  final List<String> allCourses;

  StudyMateMatch({
    required this.profile,
    required this.sharedCourses,
    required this.allCourses,
  });

  int get sharedCount => sharedCourses.length;
}
