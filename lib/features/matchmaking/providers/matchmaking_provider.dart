import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/matchmaking_repository.dart';
import '../models/study_mate_match.dart';

final matchmakingRepositoryProvider = Provider<MatchmakingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MatchmakingRepository(client);
});

/// Future provider for listing all unique courses in the system for filtering
final uniqueCoursesFilterProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(matchmakingRepositoryProvider);
  return await repository.getAllUniqueCourses();
});

/// Future provider for default suggested study partners for the user (sorted by shared courses)
final suggestedMatchesProvider = FutureProvider<List<StudyMateMatch>>((ref) async {
  final repository = ref.watch(matchmakingRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];
  return await repository.findMatches(currentUserId: currentUserId);
});

class MatchQueryParams {
  final String? major;
  final int? semester;
  final String? courseName;

  MatchQueryParams({this.major, this.semester, this.courseName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchQueryParams &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          semester == other.semester &&
          courseName == other.courseName;

  @override
  int get hashCode => major.hashCode ^ semester.hashCode ^ courseName.hashCode;
}

/// Future provider family for retrieving filtered search results
final matchmakingResultsProvider = FutureProvider.family<List<StudyMateMatch>, MatchQueryParams>((ref, params) async {
  final repository = ref.watch(matchmakingRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];
  return await repository.findMatches(
    currentUserId: currentUserId,
    major: params.major,
    semester: params.semester,
    courseName: params.courseName,
  );
});
