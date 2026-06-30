import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import '../../../shared/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});

/// Provider that extracts the current user ID from the auth state stream.
/// Rebuilds whenever the auth state changes (login, logout, token refresh).
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.whenOrNull(
    data: (state) => state.session?.user.id,
  ) ?? ref.read(supabaseClientProvider).auth.currentUser?.id;
  debugPrint('[currentUserIdProvider] userId: $userId (authState isLoading: ${authState.isLoading})');
  return userId;
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repository;
  final String? _userId;

  UserProfileNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    debugPrint('[UserProfileNotifier] Created with userId: $_userId');
    _init();
  }

  Future<void> _init() async {
    if (_userId == null) {
      debugPrint('[UserProfileNotifier] userId is null, setting state to data(null)');
      state = const AsyncValue.data(null);
      return;
    }
    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    debugPrint('[UserProfileNotifier] loadProfile starting for userId: $_userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await _repository.getProfile(_userId);
      debugPrint('[UserProfileNotifier] loadProfile result: ${profile != null ? "found" : "null"}');
      return profile;
    });
    debugPrint('[UserProfileNotifier] loadProfile final state: isLoading=${state.isLoading}, hasError=${state.hasError}, value=${state.value}');
  }

  Future<void> completeProfile({
    required String major,
    required int semester,
  }) async {
    if (_userId == null) return;
    debugPrint('[UserProfileNotifier] completeProfile starting');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.completeProfile(
        userId: _userId,
        major: major,
        semester: semester,
      );
      return await _repository.getProfile(_userId);
    });
    debugPrint('[UserProfileNotifier] completeProfile final state: isLoading=${state.isLoading}, value=${state.value}');
  }

  Future<void> updateProfile({
    required String fullName,
    required String major,
    required int semester,
  }) async {
    if (_userId == null) return;
    debugPrint('[UserProfileNotifier] updateProfile starting');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateProfile(
        userId: _userId,
        fullName: fullName,
        major: major,
        semester: semester,
      );
      return await _repository.getProfile(_userId);
    });
    debugPrint('[UserProfileNotifier] updateProfile final state: isLoading=${state.isLoading}, value=${state.value}');
  }
}

/// This provider watches [currentUserIdProvider], so it automatically
/// rebuilds with a new UserProfileNotifier whenever the auth user changes
/// (login, logout, signup).
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  debugPrint('[userProfileProvider] Building with userId: $userId');
  return UserProfileNotifier(repository, userId);
});
