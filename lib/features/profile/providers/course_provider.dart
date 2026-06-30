import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/course_repository.dart';
import '../../../shared/models/user_course.dart';
import 'profile_provider.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CourseRepository(client);
});

class UserCoursesNotifier extends StateNotifier<AsyncValue<List<UserCourse>>> {
  final CourseRepository _repository;
  final String? _userId;

  UserCoursesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    debugPrint('[UserCoursesNotifier] Created with userId: $_userId');
    _init();
  }

  Future<void> _init() async {
    if (_userId == null) {
      debugPrint('[UserCoursesNotifier] userId is null, setting state to data([])');
      state = const AsyncValue.data([]);
      return;
    }
    await loadCourses();
  }

  Future<void> loadCourses() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    debugPrint('[UserCoursesNotifier] loadCourses starting for userId: $_userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getCourses(_userId);
    });
    debugPrint('[UserCoursesNotifier] loadCourses final state: size=${state.value?.length}');
  }

  Future<void> addCourse(String courseName) async {
    if (_userId == null) return;
    debugPrint('[UserCoursesNotifier] addCourse starting for $courseName');
    
    // We can do an optimistic update or keep it simple. Let's update state synchronously:
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final newCourse = await _repository.addCourse(userId: _userId, courseName: courseName);
      return [...currentList, newCourse];
    });
    debugPrint('[UserCoursesNotifier] addCourse done');
  }

  Future<void> deleteCourse(String courseId) async {
    if (_userId == null) return;
    debugPrint('[UserCoursesNotifier] deleteCourse starting for id: $courseId');
    
    final currentList = state.value ?? [];
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await _repository.deleteCourse(courseId);
      return currentList.where((course) => course.id != courseId).toList();
    });
    debugPrint('[UserCoursesNotifier] deleteCourse done');
  }
}

final userCoursesProvider = StateNotifierProvider<UserCoursesNotifier, AsyncValue<List<UserCourse>>>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  debugPrint('[userCoursesProvider] Building with userId: $userId');
  return UserCoursesNotifier(repository, userId);
});
