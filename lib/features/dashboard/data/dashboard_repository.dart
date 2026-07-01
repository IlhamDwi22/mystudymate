import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/task.dart';

class DashboardStats {
  final int activeTasks;
  final int dueThisWeek;
  final int joinedWorkspaces;
  final List<TaskWithWorkspace> upcomingDeadlines;

  DashboardStats({
    required this.activeTasks,
    required this.dueThisWeek,
    required this.joinedWorkspaces,
    required this.upcomingDeadlines,
  });
}

class TaskWithWorkspace {
  final Task task;
  final String workspaceName;

  TaskWithWorkspace({required this.task, required this.workspaceName});
}

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<DashboardStats> getDashboardStats(String userId) async {
    debugPrint('[DashboardRepository] getDashboardStats called for userId: $userId');

    // Fetch workspaces and all their tasks
    final List<dynamic> response = await _supabase
        .from('workspaces')
        .select('id, name, tasks(*)');

    int activeTasksCount = 0;
    int dueThisWeekCount = 0;
    int workspacesCount = response.length;
    List<TaskWithWorkspace> allTasks = [];

    final now = DateTime.now();
    // Use start of day for accurate day differences
    final today = DateTime(now.year, now.month, now.day);
    final oneWeekFromToday = today.add(const Duration(days: 7));
    final threeDaysFromToday = today.add(const Duration(days: 4)); // < 4 days is 3 days

    for (final row in response) {
      final workspaceName = row['name'] as String;
      final tasksList = row['tasks'] as List? ?? [];

      for (final taskRow in tasksList) {
        final task = Task.fromJson(taskRow);
        
        if (task.status != 'done') {
          activeTasksCount++;
          
          if (task.deadline != null) {
            final taskDate = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day);
            
            // Due within 7 days
            if (taskDate.isAfter(today.subtract(const Duration(days: 1))) && 
                taskDate.isBefore(oneWeekFromToday)) {
              dueThisWeekCount++;
            }
            
            // Upcoming deadlines (within 3 days)
            if (taskDate.isAfter(today.subtract(const Duration(days: 1))) &&
                taskDate.isBefore(threeDaysFromToday)) {
              allTasks.add(TaskWithWorkspace(task: task, workspaceName: workspaceName));
            }
          }
        }
      }
    }

    // Sort allTasks by deadline
    allTasks.sort((a, b) => a.task.deadline!.compareTo(b.task.deadline!));

    // Get top 3 upcoming deadlines
    final upcomingDeadlines = allTasks.take(3).toList();

    return DashboardStats(
      activeTasks: activeTasksCount,
      dueThisWeek: dueThisWeekCount,
      joinedWorkspaces: workspacesCount,
      upcomingDeadlines: upcomingDeadlines,
    );
  }
}
