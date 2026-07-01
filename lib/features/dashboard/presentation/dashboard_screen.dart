import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/dashboard_provider.dart';
import '../data/dashboard_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.value;
    
    final statsState = ref.watch(dashboardStatsProvider);
    
    // Fallback to "User" if profile full_name is empty or not loaded yet.
    final String fullName = profile?.fullName ?? 'User';
    final String displayName = fullName.split(' ').first;
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 80,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hello, ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        ' 👋',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Let's make progress today.",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              onPressed: () {
                _showNotificationSheet(context, statsState.value?.upcomingDeadlines ?? []);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Active Tasks Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Active Tasks',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    statsState.when(
                      data: (stats) => Text(
                        '${stats.activeTasks}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF98BBFF), 
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('-', style: TextStyle(fontSize: 36)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Metrics Row: Due This Week & Joined Workspaces
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Due This Week',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          statsState.when(
                            data: (stats) => Text(
                              '${stats.dueThisWeek}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('-', style: TextStyle(fontSize: 28)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.hub_outlined,
                                color: Color(0xFFD97706),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Joined Workspaces',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          statsState.when(
                            data: (stats) => Text(
                              '${stats.joinedWorkspaces}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('-', style: TextStyle(fontSize: 28)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3. Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      bgColor: const Color(0xFFEEF2FF),
                      iconBgColor: AppColors.primary,
                      icon: Icons.workspaces_outlined,
                      title: 'Workspace',
                      subtitle: 'Manage group assignments',
                      titleColor: AppColors.primary,
                      onTap: () {
                        context.go('/workspace');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      bgColor: const Color(0xFFEFF6FF),
                      iconBgColor: AppColors.secondary,
                      icon: Icons.person_add_alt_outlined,
                      title: 'Study Mate',
                      subtitle: 'Find study partners',
                      titleColor: AppColors.secondary,
                      onTap: () {
                        context.push('/dashboard/matchmaking');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                bgColor: const Color(0xFFFFF7ED),
                iconBgColor: const Color(0xFFD97706),
                icon: Icons.folder_outlined,
                title: 'Repository',
                subtitle: 'Browse learning materials',
                titleColor: const Color(0xFFD97706),
                onTap: () {
                  context.go('/repository');
                },
              ),
              const SizedBox(height: 32),

              // 4. Upcoming Deadlines Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming Deadlines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/workspace');
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    statsState.when(
                      data: (stats) {
                        if (stats.upcomingDeadlines.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'No upcoming deadlines soon! 🎉',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          children: stats.upcomingDeadlines.map((item) {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final deadline = item.task.deadline!;
                            final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
                            final difference = taskDate.difference(today).inDays;
                            
                            String tagText = 'HIGH PRIORITY';
                            Color tagBgColor = const Color(0xFFFEE2E2);
                            Color tagTextColor = const Color(0xFFEF4444);
                            String dueText;
                            Color dueColor = const Color(0xFFEF4444);
                            Color accentColor = const Color(0xFFEF4444);
                            Color bgColor = const Color(0xFFFEF2F2);
                            Color borderColor = const Color(0xFFFEE2E2);
                            
                            if (difference < 0) {
                              dueText = 'Overdue by ${difference.abs()} days';
                            } else if (difference == 0) {
                              dueText = 'Due Today';
                            } else if (difference == 1) {
                              dueText = 'Due Tomorrow';
                            } else {
                              dueText = 'Due in $difference Days';
                              if (difference > 1) {
                                tagText = 'MEDIUM PRIORITY';
                                tagBgColor = const Color(0xFFDBEAFE);
                                tagTextColor = const Color(0xFF3B82F6);
                                dueColor = AppColors.textLight;
                                accentColor = const Color(0xFF3B82F6);
                                bgColor = const Color(0xFFEFF6FF);
                                borderColor = const Color(0xFFDBEAFE);
                              }
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildDeadlineTaskItem(
                                tagText: tagText,
                                tagBgColor: tagBgColor,
                                tagTextColor: tagTextColor,
                                dueText: dueText,
                                dueColor: dueColor,
                                title: item.task.title,
                                workspaceName: item.workspaceName,
                                accentColor: accentColor,
                                bgColor: bgColor,
                                borderColor: borderColor,
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Gagal memuat tasks')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context, List<TaskWithWorkspace> deadlines) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              if (deadlines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'Belum ada notifikasi baru',
                      style: TextStyle(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: deadlines.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = deadlines[index];
                      final deadlineStr = DateFormat('dd MMM yyyy').format(item.task.deadline!);
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFEF2F2),
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.error),
                        ),
                        title: Text(
                          item.task.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Mendekati deadline: $deadlineStr\nWorkspace: ${item.workspaceName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/workspace'); // Navigate to workspace on tap
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required Color bgColor,
    required Color iconBgColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineTaskItem({
    required String tagText,
    required Color tagBgColor,
    required Color tagTextColor,
    required String dueText,
    required Color dueColor,
    required String title,
    required String workspaceName,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      tagText,
                      style: TextStyle(
                        color: tagTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: dueColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dueText,
                        style: TextStyle(
                          color: dueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppColors.textLight,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workspaceName,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

