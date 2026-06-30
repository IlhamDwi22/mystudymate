import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/workspace_repository.dart';
import '../../../shared/models/workspace.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkspaceRepository(client);
});

class WorkspacesNotifier extends StateNotifier<AsyncValue<List<Workspace>>> {
  final WorkspaceRepository _repository;
  final String? _userId;

  WorkspacesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    debugPrint('[WorkspacesNotifier] Created with userId: $_userId');
    _init();
  }

  Future<void> _init() async {
    if (_userId == null) {
      debugPrint('[WorkspacesNotifier] userId is null, setting state to empty list');
      state = const AsyncValue.data([]);
      return;
    }
    await loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    debugPrint('[WorkspacesNotifier] loadWorkspaces starting for userId: $_userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final list = await _repository.getWorkspaces(_userId);
      debugPrint('[WorkspacesNotifier] loadWorkspaces success: ${list.length} workspaces');
      return list;
    });
  }

  Future<void> createWorkspace(String name) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[WorkspacesNotifier] createWorkspace aborted: userId is null');
      return;
    }
    debugPrint('[WorkspacesNotifier] createWorkspace starting: "$name"');
    // Tidak set loading di sini agar modal bottom sheet tidak ikut rebuild
    // dan menyebabkan BoxConstraints infinite width error.
    // Loading state di UI ditangani oleh isSubmitting di modal.
    try {
      await _repository.createWorkspace(
        name: name,
        ownerId: userId,
      );
      final list = await _repository.getWorkspaces(userId);
      state = AsyncValue.data(list);
      debugPrint('[WorkspacesNotifier] createWorkspace complete: ${list.length} workspaces');
    } catch (e, st) {
      debugPrint('[WorkspacesNotifier] createWorkspace error: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    final userId = _userId;
    if (userId == null) return;
    debugPrint('[WorkspacesNotifier] deleteWorkspace starting: "$workspaceId"');
    try {
      await _repository.deleteWorkspace(workspaceId);
      final list = await _repository.getWorkspaces(userId);
      state = AsyncValue.data(list);
      debugPrint('[WorkspacesNotifier] deleteWorkspace complete: ${list.length} workspaces');
    } catch (e, st) {
      debugPrint('[WorkspacesNotifier] deleteWorkspace error: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider that maintains the state of the workspaces list.
/// Automatically re-initializes when the current user ID changes.
final workspacesProvider = StateNotifierProvider<WorkspacesNotifier, AsyncValue<List<Workspace>>>((ref) {
  final repository = ref.watch(workspaceRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return WorkspacesNotifier(repository, userId);
});
