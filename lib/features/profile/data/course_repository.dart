import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_course.dart';

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository(this._supabase);

  /// Fetch all courses for a user from user_courses table
  Future<List<UserCourse>> getCourses(String userId) async {
    debugPrint('[CourseRepository] getCourses called for userId: $userId');
    
    final response = await _supabase
        .from('user_courses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    debugPrint('[CourseRepository] Raw response: $response');
    
    return (response as List<dynamic>)
        .map((e) => UserCourse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a course
  Future<UserCourse> addCourse({
    required String userId,
    required String courseName,
  }) async {
    debugPrint('[CourseRepository] addCourse called for userId: $userId, course: $courseName');
    
    final response = await _supabase
        .from('user_courses')
        .insert({
          'user_id': userId,
          'course_name': courseName,
        })
        .select()
        .single();

    debugPrint('[CourseRepository] Added course response: $response');
    return UserCourse.fromJson(response);
  }

  /// Delete a course by its ID
  Future<void> deleteCourse(String courseId) async {
    debugPrint('[CourseRepository] deleteCourse called for courseId: $courseId');
    
    await _supabase
        .from('user_courses')
        .delete()
        .eq('id', courseId);
        
    debugPrint('[CourseRepository] deleteCourse complete');
  }
}
