import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/workspace.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/user_profile.dart';
import '../providers/workspace_detail_provider.dart';
import '../providers/workspace_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../matchmaking/providers/friend_provider.dart';
import '../../matchmaking/models/friend_models.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final Workspace workspace;

  const WorkspaceDetailScreen({
    super.key,
    required this.workspace,
  });

  @override
  ConsumerState<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _kanbanPageController;
  int _currentKanbanPage = 0;
  final TextEditingController _memberSearchController = TextEditingController();
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kanbanPageController = PageController(viewportFraction: 0.9);
    _memberSearchController.addListener(() {
      setState(() {
        _memberSearchQuery = _memberSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kanbanPageController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  void _showInviteMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return _InviteMemberDialog(workspaceId: widget.workspace.id);
      },
    );
  }

  void _showDeleteWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Hapus Workspace',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus workspace "${widget.workspace.name}"? Seluruh tugas dan data di dalamnya akan dihapus permanen.',
          style: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await ref.read(workspacesProvider.notifier).deleteWorkspace(widget.workspace.id);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Workspace "${widget.workspace.name}" berhasil dihapus'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus workspace: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, UserProfile member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Keluarkan Anggota',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Text(
          'Apakah Anda yakin ingin mengeluarkan ${member.fullName} dari workspace ini?',
          style: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await ref
                    .read(workspaceMembersProvider(widget.workspace.id).notifier)
                    .removeMember(member.id);
                ref.invalidate(workspacesProvider);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Berhasil mengeluarkan ${member.fullName}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengeluarkan anggota: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider(widget.workspace.id));
    final membersState = ref.watch(workspaceMembersProvider(widget.workspace.id));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.workspace.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteWorkspaceDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hapus Workspace',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isTasksTab = _tabController.index == 0;
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const Icon(Icons.add, size: 24),
            label: Text(
              isTasksTab ? 'Task' : 'Invite Member',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            onPressed: isTasksTab
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(
                          workspaceId: widget.workspace.id,
                        ),
                      ),
                    ).then((_) {
                      ref.read(tasksProvider(widget.workspace.id).notifier).loadTasks();
                      ref.invalidate(workspacesProvider);
                    });
                  }
                : () => _showInviteMemberDialog(context),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tasks Kanban Tab
          tasksState.when(
            data: (tasks) => _buildKanbanBoard(tasks),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Gagal memuat tugas: $err')),
          ),

          // 2. Members Tab
          membersState.when(
            data: (members) => _buildMembersList(members, currentUserId),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Gagal memuat anggota: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard(List<Task> tasks) {
    final todoTasks = tasks.where((t) => t.status == 'todo').toList();
    final doingTasks = tasks.where((t) => t.status == 'doing').toList();
    final doneTasks = tasks.where((t) => t.status == 'done').toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        // Kanban Indicators Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKanbanTabIndicator('TODO', todoTasks.length, const Color(0xFFADC6FF), 0),
              _buildKanbanTabIndicator('DOING', doingTasks.length, const Color(0xFFFBBF24), 1),
              _buildKanbanTabIndicator('DONE', doneTasks.length, const Color(0xFF22C55E), 2),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Kanban columns sliding view
        Expanded(
          child: PageView(
            controller: _kanbanPageController,
            onPageChanged: (pageIndex) {
              setState(() {
                _currentKanbanPage = pageIndex;
              });
            },
            children: [
              _buildKanbanColumn('TODO', todoTasks, const Color(0xFFADC6FF)),
              _buildKanbanColumn('DOING', doingTasks, const Color(0xFFFBBF24)),
              _buildKanbanColumn('DONE', doneTasks, const Color(0xFF22C55E)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanTabIndicator(String title, int count, Color color, int pageIndex) {
    final isSelected = _currentKanbanPage == pageIndex;
    return GestureDetector(
      onTap: () {
        _kanbanPageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.textDark : AppColors.textLight,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<Task> columnTasks, Color columnColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: columnColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${columnTasks.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: columnTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada tugas',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: columnTasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = columnTasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    // Determine priority styling
    Color tagBgColor;
    Color tagTextColor;
    String priorityText = 'Medium Priority';
    
    // We mock priority or read from description/title suffix for Sprint simplicity, 
    // or we assume some tasks have custom priorities based on their title.
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

    // Format deadline
    String dueText = 'No deadline';
    if (task.deadline != null) {
      final now = DateTime.now();
      final diff = task.deadline!.difference(now);
      if (diff.inDays == 0) {
        dueText = 'Due Today';
      } else if (diff.inDays == 1) {
        dueText = 'Due Tomorrow';
      } else if (diff.inDays > 1 && diff.inDays < 7) {
        dueText = 'Due in ${diff.inDays} Days';
      } else {
        dueText = 'Due ${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(
                  task: task,
                  workspaceName: widget.workspace.name,
                ),
              ),
            ).then((_) {
              ref.read(tasksProvider(widget.workspace.id).notifier).loadTasks();
              ref.invalidate(workspacesProvider);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priorityText,
                        style: TextStyle(
                          color: tagTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: AppColors.textLight, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      dueText,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: const Text(
                        'A',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Alex',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textLight),
                    ),
                    const Spacer(),
                    const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textLight),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList(List<UserProfile> members, String? currentUserId) {
    final filteredMembers = members.where((m) {
      return m.fullName.toLowerCase().contains(_memberSearchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Search Members
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _memberSearchController,
              decoration: const InputDecoration(
                hintText: 'Search members...',
                prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List of Members
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(
                    child: Text(
                      'Anggota tidak ditemukan',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredMembers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      final isOwner = member.id == widget.workspace.ownerId;
                      
                      // Mock photo URLs for visual premium design
                      final indexHash = member.fullName.codeUnits.fold(0, (prev, element) => prev + element);
                      final avatarUrl = isOwner
                          ? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&q=80&w=200'
                          : 'https://images.unsplash.com/photo-${1500000000000 + (indexHash % 1000000)}?auto=format&fit=crop&q=80&w=200';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(avatarUrl),
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isOwner
                                          ? AppColors.primary
                                          : AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOwner ? 'Owner' : 'Member',
                                      style: TextStyle(
                                        color: isOwner ? Colors.white : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isOwner)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz, color: AppColors.textLight),
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    _showRemoveMemberDialog(context, member);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove_outlined, color: AppColors.error, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Keluarkan Anggota',
                                          style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final String workspaceId;

  const _InviteMemberDialog({required this.workspaceId});

  @override
  ConsumerState<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsListProvider);
    final workspaceMembers = ref.watch(workspaceMembersProvider(widget.workspaceId));

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Undang Teman',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih teman yang ingin diundang:',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: friendsState.when(
                data: (friends) {
                  if (friends.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Kamu belum memiliki teman.\nSilakan cari di halaman Find Study Mate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final friend = friends[index];

                      // Check if already a member
                      bool isMember = false;
                      workspaceMembers.whenData((members) {
                        isMember = members.any((m) => m.id == friend.id);
                      });

                      final initials = friend.fullName.isNotEmpty
                          ? friend.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                          : 'U';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(25),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          friend.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          friend.major,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isMember
                            ? const Text(
                                'Terdaftar',
                                style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            : isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: AppColors.primary),
                                      ),
                                    ),
                                    onPressed: () => _inviteFriend(friend),
                                    child: const Text('Undang', style: TextStyle(fontSize: 12)),
                                  ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Future<void> _inviteFriend(FriendProfile friend) async {
    setState(() {
      isSubmitting = true;
    });

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(workspaceMembersProvider(widget.workspaceId).notifier)
          .inviteMemberById(friend.id);
      
      ref.invalidate(workspacesProvider);

      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Berhasil mengundang ${friend.fullName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
