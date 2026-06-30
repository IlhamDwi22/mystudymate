import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workspace_repository.dart';
import '../providers/workspace_provider.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/user_profile.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final WorkspaceRepository _repository;
  final String _workspaceId;

  TasksNotifier(this._repository, this._workspaceId) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getTasks(_workspaceId);
    });
  }

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createTask(task);
      return await _repository.getTasks(_workspaceId);
    });
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateTask(task);
      return await _repository.getTasks(_workspaceId);
    });
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteTask(taskId);
      return await _repository.getTasks(_workspaceId);
    });
  }
}

/// Family provider for managing tasks within a specific workspace.
final tasksProvider = StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>((ref, workspaceId) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return TasksNotifier(repository, workspaceId);
});

class WorkspaceMembersNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  final WorkspaceRepository _repository;
  final String _workspaceId;

  WorkspaceMembersNotifier(this._repository, this._workspaceId) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getWorkspaceMembers(_workspaceId);
    });
  }

  Future<void> inviteMember(String fullName) async {
    // Do NOT wrap in AsyncValue.guard() — the UI's catch block needs the
    // exception to propagate so it can show a SnackBar error message.
    try {
      await _repository.inviteMemberByName(_workspaceId, fullName);
      final members = await _repository.getWorkspaceMembers(_workspaceId);
      state = AsyncValue.data(members);
    } catch (e) {
      // Reload current members so the list stays valid
      state = await AsyncValue.guard(() async {
        return await _repository.getWorkspaceMembers(_workspaceId);
      });
      // Rethrow so the dialog's catch block receives it
      rethrow;
    }
  }

  Future<void> removeMember(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.removeMember(_workspaceId, userId);
      return await _repository.getWorkspaceMembers(_workspaceId);
    });
  }
}

/// Family provider for managing members of a specific workspace.
final workspaceMembersProvider = StateNotifierProvider.family<WorkspaceMembersNotifier, AsyncValue<List<UserProfile>>, String>((ref, workspaceId) {
  final repository = ref.watch(workspaceRepositoryProvider);
  return WorkspaceMembersNotifier(repository, workspaceId);
});
