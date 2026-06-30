import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/task.dart';
import '../providers/workspace_detail_provider.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;
  final String workspaceName;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.workspaceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine priority styling
    Color tagBgColor;
    Color tagTextColor;
    String priorityText = 'Medium Priority';
    
    final titleLower = task.title.toLowerCase();
    if (titleLower.contains('report') || titleLower.contains('laporan') || titleLower.contains('db') || titleLower.contains('database')) {
      priorityText = 'High Priority';
      tagBgColor = const Color(0xFFFEE2E2);
      tagTextColor = const Color(0xFFEF4444);
    } else if (titleLower.contains('ai') || titleLower.contains('presentation') || titleLower.contains('presentasi')) {
      priorityText = 'Medium Priority';
      tagBgColor = const Color(0xFFDBEAFE);
      tagTextColor = const Color(0xFF3B82F6);
    } else {
      priorityText = 'Low Priority';
      tagBgColor = const Color(0xFFF0FDF4);
      tagTextColor = const Color(0xFF22C55E);
    }

    // Format deadline date
    String dueText = 'No deadline';
    if (task.deadline != null) {
      dueText = '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}';
    }

    String createdText = '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Tags Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (priorityText == 'High Priority')
                          const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
                        if (priorityText == 'High Priority') const SizedBox(width: 4),
                        Text(
                          priorityText,
                          style: TextStyle(
                            color: tagTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description Card
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description ?? 'Belum ada deskripsi untuk tugas ini.',
                      style: const TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activity Timeline Card
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.update, color: AppColors.textDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Activity Timeline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Vertical items
                    _buildTimelineItem(
                      title: 'Alex created this task',
                      time: 'Oct 18, 10:00 AM',
                      color: const Color(0xFF3B82F6),
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      title: 'Alex updated the priority to High',
                      time: 'Oct 19, 02:30 PM',
                      color: const Color(0xFFD97706),
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      title: 'Alex assigned this task to Budi',
                      time: 'Oct 20, 09:15 AM',
                      color: const Color(0xFF45607E),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Meta Details Card
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildMetaRow(
                      icon: Icons.person_outline,
                      label: 'Assignee',
                      valueWidget: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: const NetworkImage(
                              'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&q=80&w=200',
                            ),
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Alex',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _buildMetaRow(
                      icon: Icons.folder_outlined,
                      label: 'Workspace',
                      valueWidget: Text(
                        workspaceName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _buildMetaRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Due Date',
                      valueWidget: Text(
                        dueText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _buildMetaRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Created Date',
                      valueWidget: Text(
                        createdText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(
                        workspaceId: task.workspaceId,
                        task: task,
                      ),
                    ),
                  ).then((updated) {
                    if (updated == true) {
                      navigator.pop();
                    }
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Tugas'),
                      content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(tasksProvider(task.workspaceId).notifier).deleteTask(task.id);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Tugas berhasil dihapus!'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: const Color(0xFFCBD5E1),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
        const Spacer(),
        valueWidget,
      ],
    );
  }
}
