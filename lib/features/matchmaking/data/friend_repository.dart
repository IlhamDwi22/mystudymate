import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_models.dart';

class FriendRepository {
  final SupabaseClient _supabase;

  FriendRepository(this._supabase);

  /// Send a friend request to another user
  Future<void> sendFriendRequest(String receiverId) async {
    final senderId = _supabase.auth.currentUser!.id;
    debugPrint('[FriendRepository] Sending friend request: $senderId → $receiverId');

    await _supabase.from('friend_requests').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
    });
  }

  /// Get pending incoming friend requests (via RPC)
  Future<List<FriendRequest>> getPendingRequests() async {
    debugPrint('[FriendRepository] Fetching pending friend requests');

    final List<dynamic> response =
        await _supabase.rpc('get_pending_friend_requests');

    return response
        .map((e) => FriendRequest.fromRpc(e as Map<String, dynamic>))
        .toList();
  }

  /// Accept a friend request (via RPC - creates bidirectional friendship)
  Future<void> acceptRequest(String requestId) async {
    debugPrint('[FriendRepository] Accepting friend request: $requestId');

    await _supabase.rpc('accept_friend_request', params: {
      'request_id': requestId,
    });
  }

  /// Reject a friend request
  Future<void> rejectRequest(String requestId) async {
    debugPrint('[FriendRepository] Rejecting friend request: $requestId');

    await _supabase
        .from('friend_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  /// Get all friends (via RPC)
  Future<List<FriendProfile>> getMyFriends() async {
    debugPrint('[FriendRepository] Fetching friends list');

    final List<dynamic> response = await _supabase.rpc('get_my_friends');

    return response
        .map((e) => FriendProfile.fromRpc(e as Map<String, dynamic>))
        .toList();
  }

  /// Get sent friend request statuses (to show button states on matchmaking cards)
  Future<Map<String, String>> getSentRequestStatuses() async {
    debugPrint('[FriendRepository] Fetching sent request statuses');

    final List<dynamic> response =
        await _supabase.rpc('get_sent_friend_request_statuses');

    final Map<String, String> statuses = {};
    for (final row in response) {
      statuses[row['receiver_id'] as String] = row['status'] as String;
    }
    return statuses;
  }

  /// Check if already friends with a specific user
  Future<bool> isFriendWith(String userId) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('friends')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('friend_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Remove a friend (deletes both directions)
  Future<void> removeFriend(String friendId) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    debugPrint('[FriendRepository] Removing friend: $friendId');

    // Delete both directions
    await _supabase
        .from('friends')
        .delete()
        .eq('user_id', currentUserId)
        .eq('friend_id', friendId);

    await _supabase
        .from('friends')
        .delete()
        .eq('user_id', friendId)
        .eq('friend_id', currentUserId);
  }
}
