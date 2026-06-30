import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/workspace.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/task.dart';

class WorkspaceRepository {
  final SupabaseClient _supabase;

  WorkspaceRepository(this._supabase);

  /// Fetch workspaces owned or accessible by the user
  Future<List<Workspace>> getWorkspaces(String userId) async {
    debugPrint('[WorkspaceRepository] getWorkspaces called for userId: $userId');
    
    // Fetch workspaces along with their tasks.
    // NOTE: workspace_members RLS only shows the caller's own row,
    // so we use the RPC `get_workspace_member_count` for accurate counts.
    final List<dynamic> response = await _supabase
        .from('workspaces')
        .select('*, tasks(id, status)')
        .order('created_at', ascending: false);

    debugPrint('[WorkspaceRepository] getWorkspaces response: $response');

    final List<Workspace> workspaces = [];
    for (final row in response) {
      final tasksList = row['tasks'] as List? ?? [];
      final activeTaskCount = tasksList
          .where((t) => t['status'] != 'done')
          .length;

      // Try RPC for accurate member count (bypasses RLS)
      int memberCount = 1;
      try {
        final count = await _supabase.rpc('get_workspace_member_count', params: {
          'p_workspace_id': row['id'] as String,
        });
        memberCount = (count as int?) ?? 1;
        if (memberCount < 1) memberCount = 1;
      } catch (e) {
        debugPrint('[WorkspaceRepository] get_workspace_member_count RPC failed: $e, defaulting to 1');
      }

      workspaces.add(Workspace.fromJson(
        row,
        memberCount: memberCount,
        activeTaskCount: activeTaskCount,
      ));
    }
    return workspaces;
  }

  /// Create a new workspace and auto-add the owner as a member
  Future<Workspace> createWorkspace({
    required String name,
    required String ownerId,
  }) async {
    debugPrint('[WorkspaceRepository] createWorkspace called: name="$name", ownerId=$ownerId');
    
    // 1. Insert into workspaces
    final Map<String, dynamic> workspaceRow = await _supabase
        .from('workspaces')
        .insert({
          'name': name,
          'owner_id': ownerId,
        })
        .select()
        .single();
    
    final workspaceId = workspaceRow['id'] as String;
    debugPrint('[WorkspaceRepository] Created workspace row: $workspaceRow');

    // 2. Auto-add owner as a member (handle potential duplicate key if DB trigger already added it)
    try {
      await _supabase.from('workspace_members').insert({
        'workspace_id': workspaceId,
        'user_id': ownerId,
      });
      debugPrint('[WorkspaceRepository] Added owner as member for workspace: $workspaceId');
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isDuplicate = errStr.contains('duplicate') ||
          errStr.contains('23505') ||
          errStr.contains('conflict') ||
          (e is PostgrestException && e.code == '23505');
      if (isDuplicate) {
        debugPrint('[WorkspaceRepository] Owner already added as member (duplicate key ignored)');
      } else {
        rethrow;
      }
    }

    return Workspace.fromJson(workspaceRow, memberCount: 1, activeTaskCount: 0);
  }

  /// Fetch all tasks for a workspace
  Future<List<Task>> getTasks(String workspaceId) async {
    debugPrint('[WorkspaceRepository] getTasks called for workspaceId: $workspaceId');
    final List<dynamic> response = await _supabase
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: true);
    return response.map((row) => Task.fromJson(row)).toList();
  }

  /// Create a new task
  Future<Task> createTask(Task task) async {
    debugPrint('[WorkspaceRepository] createTask called: title="${task.title}"');
    final Map<String, dynamic> row = await _supabase
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();
    return Task.fromJson(row);
  }

  /// Update an existing task
  Future<Task> updateTask(Task task) async {
    debugPrint('[WorkspaceRepository] updateTask called: id="${task.id}", title="${task.title}"');
    final Map<String, dynamic> row = await _supabase
        .from('tasks')
        .update({
          'title': task.title,
          'description': task.description,
          'deadline': task.deadline?.toIso8601String(),
          'status': task.status,
          'assignee_id': task.assigneeId,
        })
        .eq('id', task.id)
        .select()
        .single();
    return Task.fromJson(row);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    debugPrint('[WorkspaceRepository] deleteTask called: id="$taskId"');
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  /// Fetch members of a workspace.
  ///
  /// Uses the RPC `get_workspace_members` (SECURITY DEFINER) to see ALL
  /// members regardless of RLS. Falls back to direct query if RPC is missing.
  Future<List<UserProfile>> getWorkspaceMembers(String workspaceId) async {
    debugPrint('[WorkspaceRepository] getWorkspaceMembers called for workspaceId: $workspaceId');

    // --- Attempt 1: Use RPC (returns all members with profile info) ---
    try {
      final List<dynamic> rpcResponse = await _supabase.rpc(
        'get_workspace_members',
        params: {'p_workspace_id': workspaceId},
      );
      debugPrint('[WorkspaceRepository] getWorkspaceMembers RPC returned ${rpcResponse.length} members');

      return rpcResponse.map((row) {
        return UserProfile(
          id: row['user_id'] as String,
          fullName: row['full_name'] as String? ?? 'Anggota',
          major: row['major'] as String? ?? '',
          semester: row['semester'] as int? ?? 1,
          createdAt: row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isRpcMissing = errStr.contains('could not find the function') ||
          errStr.contains('42883');
      if (!isRpcMissing) rethrow;
      debugPrint('[WorkspaceRepository] get_workspace_members RPC not found, falling back to direct query');
    }

    // --- Attempt 2: Direct query (only sees own membership due to RLS) ---
    final List<dynamic> response = await _supabase
        .from('workspace_members')
        .select('user_id, profiles(*)')
        .eq('workspace_id', workspaceId);
    
    debugPrint('[WorkspaceRepository] getWorkspaceMembers direct query returned ${response.length} members');

    return response.map((row) {
      final profileData = row['profiles'] as Map<String, dynamic>?;
      return UserProfile(
        id: profileData?['id'] as String? ?? row['user_id'] as String,
        fullName: profileData?['full_name'] as String? ?? 'Anggota',
        major: profileData?['major'] as String? ?? '',
        semester: profileData?['semester'] as int? ?? 1,
        createdAt: profileData?['created_at'] != null
            ? DateTime.parse(profileData!['created_at'] as String)
            : DateTime.now(),
      );
    }).toList();
  }

  /// Invite a member to the workspace by their full name.
  ///
  /// Uses the Supabase RPC function `invite_member_by_name` (SECURITY DEFINER)
  /// which can look up other users' profiles and insert workspace_members rows
  /// regardless of RLS. Falls back to direct queries if the RPC is not deployed.
  Future<void> inviteMemberByName(String workspaceId, String fullName) async {
    debugPrint('[WorkspaceRepository] inviteMemberByName called: workspaceId="$workspaceId", name="$fullName"');

    // --- Attempt 1: Use RPC function (recommended, bypasses RLS) ---
    try {
      await _supabase.rpc('invite_member_by_name', params: {
        'p_workspace_id': workspaceId,
        'p_full_name': fullName,
      });
      debugPrint('[WorkspaceRepository] inviteMemberByName via RPC success');
      return;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // If the RPC function doesn't exist yet, fall through to direct approach
      final isRpcMissing = errStr.contains('could not find the function') ||
          errStr.contains('function') && errStr.contains('does not exist') ||
          errStr.contains('42883'); // PostgreSQL error code for undefined_function

      if (isRpcMissing) {
        debugPrint('[WorkspaceRepository] RPC not found, falling back to direct queries');
      } else {
        // RPC exists but returned an application error (e.g. "user not found")
        // The RPC raises exceptions with user-friendly messages
        debugPrint('[WorkspaceRepository] inviteMemberByName RPC error: $e');
        rethrow;
      }
    }

    // --- Attempt 2: Direct queries (only works if RLS allows reading other profiles) ---
    debugPrint('[WorkspaceRepository] inviteMemberByName fallback: direct query for "$fullName"');

    // Find profile by name
    final profileRow = await _supabase
        .from('profiles')
        .select('id')
        .ilike('full_name', fullName)
        .maybeSingle();

    debugPrint('[WorkspaceRepository] Profile lookup result: $profileRow');

    if (profileRow == null) {
      throw Exception('Pengguna dengan nama "$fullName" tidak ditemukan. '
          'Pastikan nama lengkap benar (case-insensitive). '
          'Jika Anda sudah yakin nama benar, jalankan SQL RPC function di Supabase.');
    }

    final String userId = profileRow['id'] as String;

    // Check if already a member
    final existingMember = await _supabase
        .from('workspace_members')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('Pengguna "$fullName" sudah menjadi anggota workspace ini.');
    }

    // Insert membership
    await _supabase.from('workspace_members').insert({
      'workspace_id': workspaceId,
      'user_id': userId,
    });
    debugPrint('[WorkspaceRepository] inviteMemberByName direct insert success');
  }

  /// Remove a member from the workspace
  Future<void> removeMember(String workspaceId, String userId) async {
    debugPrint('[WorkspaceRepository] removeMember called: workspaceId="$workspaceId", userId="$userId"');
    await _supabase
        .from('workspace_members')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId);
  }

  /// Delete a workspace
  Future<void> deleteWorkspace(String workspaceId) async {
    debugPrint('[WorkspaceRepository] deleteWorkspace called: id="$workspaceId"');
    await _supabase.from('workspaces').delete().eq('id', workspaceId);
  }
}

