import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return DashboardStats(
      activeTasks: 0,
      dueThisWeek: 0,
      joinedWorkspaces: 0,
      upcomingDeadlines: [],
    );
  }

  return repository.getDashboardStats(userId);
});
