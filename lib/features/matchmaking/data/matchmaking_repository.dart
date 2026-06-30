import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_profile.dart';
import '../models/study_mate_match.dart';

class MatchmakingRepository {
  final SupabaseClient _supabase;

  MatchmakingRepository(this._supabase);

  /// Fetch matchmaking recommendations for the user
  Future<List<StudyMateMatch>> findMatches({
    required String currentUserId,
    String? major,
    int? semester,
    String? courseName,
  }) async {
    debugPrint('[MatchmakingRepository] findMatches called: currentUserId=$currentUserId, major=$major, semester=$semester, course=$courseName');

    // 1. Fetch current user's courses to calculate intersection
    final List<dynamic> myCoursesResponse = await _supabase
        .from('user_courses')
        .select('course_name')
        .eq('user_id', currentUserId);
    
    final Set<String> myCourses = myCoursesResponse
        .map((e) => e['course_name'] as String)
        .toSet();

    debugPrint('[MatchmakingRepository] Current user courses: $myCourses');

    // 2. Fetch other users' profiles along with their user_courses in one query
    var query = _supabase
        .from('profiles')
        .select('*, user_courses(course_name)')
        .neq('id', currentUserId);

    if (major != null && major != 'All' && major.isNotEmpty) {
      query = query.eq('major', major);
    }
    if (semester != null && semester != 0) {
      query = query.eq('semester', semester);
    }

    final List<dynamic> response = await query;
    debugPrint('[MatchmakingRepository] Profiles fetched: ${response.length}');

    final List<StudyMateMatch> matches = [];

    for (final row in response) {
      final String profileId = row['id'] as String;
      final String fullName = row['full_name'] as String? ?? 'Mahasiswa';
      final String majorName = row['major'] as String? ?? '';
      final int sem = row['semester'] as int? ?? 1;
      final DateTime createdAt = row['created_at'] != null 
          ? DateTime.parse(row['created_at'] as String) 
          : DateTime.now();

      final profile = UserProfile(
        id: profileId,
        fullName: fullName,
        major: majorName,
        semester: sem,
        createdAt: createdAt,
      );

      final List<dynamic> coursesList = row['user_courses'] as List? ?? [];
      final List<String> theirCourses = coursesList
          .map((e) => e['course_name'] as String)
          .toList();

      final List<String> shared = theirCourses
          .where((c) => myCourses.contains(c))
          .toList();

      // Filter by course if specified
      if (courseName != null && courseName != 'All Courses' && courseName.isNotEmpty) {
        final matchesCourse = theirCourses.any((c) => c.toLowerCase().trim() == courseName.toLowerCase().trim());
        if (!matchesCourse) {
          continue;
        }
      }

      matches.add(StudyMateMatch(
        profile: profile,
        sharedCourses: shared,
        allCourses: theirCourses,
      ));
    }

    // Sort by shared courses count descending
    matches.sort((a, b) => b.sharedCourses.length.compareTo(a.sharedCourses.length));
    debugPrint('[MatchmakingRepository] Matched study partners: ${matches.length}');
    return matches;
  }

  /// Get list of all distinct courses taken by students for filter dropdown
  Future<List<String>> getAllUniqueCourses() async {
    try {
      final List<dynamic> response = await _supabase
          .from('user_courses')
          .select('course_name');
      
      final Set<String> courses = response
          .map((e) => (e['course_name'] as String).trim())
          .toSet();
          
      final sortedList = courses.toList()..sort();
      return sortedList;
    } catch (e) {
      debugPrint('[MatchmakingRepository] getAllUniqueCourses error: $e');
      return [];
    }
  }
}
