import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/friend_repository.dart';
import '../models/friend_models.dart';

/// Repository provider
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FriendRepository(client);
});

/// Pending incoming friend requests
final pendingFriendRequestsProvider =
    StateNotifierProvider<PendingRequestsNotifier, AsyncValue<List<FriendRequest>>>((ref) {
  final repository = ref.watch(friendRepositoryProvider);
  return PendingRequestsNotifier(repository);
});

class PendingRequestsNotifier extends StateNotifier<AsyncValue<List<FriendRequest>>> {
  final FriendRepository _repository;

  PendingRequestsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repository.getPendingRequests();
      state = AsyncValue.data(requests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    await _repository.acceptRequest(requestId);
    await load(); // Refresh the list
  }

  Future<void> rejectRequest(String requestId) async {
    await _repository.rejectRequest(requestId);
    await load(); // Refresh the list
  }
}

/// Friends list
final friendsListProvider =
    StateNotifierProvider<FriendsListNotifier, AsyncValue<List<FriendProfile>>>((ref) {
  final repository = ref.watch(friendRepositoryProvider);
  return FriendsListNotifier(repository);
});

class FriendsListNotifier extends StateNotifier<AsyncValue<List<FriendProfile>>> {
  final FriendRepository _repository;

  FriendsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final friends = await _repository.getMyFriends();
      state = AsyncValue.data(friends);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFriend(String friendId) async {
    await _repository.removeFriend(friendId);
    await load();
  }
}

/// Sent friend request statuses (receiver_id -> status)
final sentRequestStatusesProvider = FutureProvider<Map<String, String>>((ref) async {
  final repository = ref.watch(friendRepositoryProvider);
  return await repository.getSentRequestStatuses();
});

/// Pending requests count (for badge on notification bell)
final pendingRequestsCountProvider = Provider<int>((ref) {
  final state = ref.watch(pendingFriendRequestsProvider);
  return state.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
