import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/friend_provider.dart';
import '../models/study_mate_match.dart';

class StudyMateSearchScreen extends ConsumerStatefulWidget {
  const StudyMateSearchScreen({super.key});

  @override
  ConsumerState<StudyMateSearchScreen> createState() => _StudyMateSearchScreenState();
}

class _WorkspaceDetailNotifier extends StateNotifier<bool> {
  _WorkspaceDetailNotifier() : super(false);
}

class _StudyMateSearchScreenState extends ConsumerState<StudyMateSearchScreen> {
  String? _selectedMajor = 'All';
  int _selectedSemester = 0; // 0 represents "All"
  String _selectedCourse = 'All Courses';

  final List<String> _majors = [
    'All',
    'D3 Teknik Informatika',
    'D4 Teknik Rekayasa Komputer',
    'D3 Akuntansi',
    'D4 Administrasi Bisnis',
  ];

  final List<int> _semesters = [0, 1, 2, 3, 4, 5, 6, 7, 8];

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final coursesState = ref.watch(uniqueCoursesFilterProvider);

    final currentUser = profileState.value;
    final initials = currentUser != null && currentUser.fullName.isNotEmpty
        ? currentUser.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Find Study Mate',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_outlined, color: AppColors.textLight),
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(pendingRequestsCountProvider);
                    if (count == 0) return const SizedBox();
                    return Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () {
              context.push('/dashboard/matchmaking/friend-requests');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Filter Card
              _buildFilterCard(context, coursesState),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, AsyncValue<List<String>> coursesState) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Major Select
            const Text(
              'Program Study',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMajor,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: _majors.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m == 'All' ? 'All Majors' : m),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMajor = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Semester & Course Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Semester',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        isExpanded: true,
                        items: _semesters.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == 0 ? 'All Semesters' : 'Sem $s',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSemester = val ?? 0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      coursesState.when(
                        data: (courses) {
                          // Ensure selected course is in list
                          final itemsList = ['All Courses', ...courses];
                          if (!itemsList.contains(_selectedCourse)) {
                            _selectedCourse = 'All Courses';
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedCourse,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            isExpanded: true,
                            items: itemsList.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCourse = val ?? 'All Courses';
                              });
                            },
                          );
                        },
                        loading: () => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [DropdownMenuItem(value: 'loading', child: Text('Loading...'))],
                          onChanged: (_) {},
                        ),
                        error: (_, __) => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [DropdownMenuItem(value: 'error', child: Text('Error loading courses'))],
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: () {
                context.push('/dashboard/matchmaking/results', extra: {
                  'major': _selectedMajor,
                  'semester': _selectedSemester,
                  'course': _selectedCourse,
                });
              },
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Find Study Partners',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, StudyMateMatch match) {
    // Generate avatar color based on name hash
    final nameHash = match.profile.fullName.codeUnits.fold(0, (prev, elem) => prev + elem);
    final initials = match.profile.fullName.isNotEmpty
        ? match.profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'M';
    final avatarColor = Colors.primaries[nameHash % Colors.primaries.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPartnerDetailSheet(context, match),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor.withAlpha(25),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              match.profile.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Shared courses badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F1FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${match.sharedCount} Shared',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.profile.major,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Semester Badge & Course Icons
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Semester ${match.profile.semester}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Course icons
                          ...match.allCourses.take(3).map((course) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Icon(
                                  _getCourseIcon(course),
                                  size: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCourseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('data') || lower.contains('database') || lower.contains('basis data')) {
      return Icons.storage_outlined;
    } else if (lower.contains('mobile') || lower.contains('pemrograman mobile')) {
      return Icons.phone_android_outlined;
    } else if (lower.contains('intelligence') || lower.contains('ai') || lower.contains('kecerdasan buatan')) {
      return Icons.psychology_outlined;
    } else if (lower.contains('cloud') || lower.contains('komputasi awan')) {
      return Icons.cloud_outlined;
    } else if (lower.contains('network') || lower.contains('jaringan')) {
      return Icons.settings_ethernet_outlined;
    } else if (lower.contains('web')) {
      return Icons.language_outlined;
    } else if (lower.contains('security') || lower.contains('keamanan')) {
      return Icons.security_outlined;
    }
    return Icons.menu_book_outlined;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Belum ada rekomendasi.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartnerDetailSheet(BuildContext context, StudyMateMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _PartnerDetailBottomSheet(match: match),
        );
      },
    );
  }
}

class _PartnerDetailBottomSheet extends ConsumerWidget {
  final StudyMateMatch match;

  const _PartnerDetailBottomSheet({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = match.profile.fullName.isNotEmpty
        ? match.profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'M';
    final nameHash = match.profile.fullName.codeUnits.fold(0, (prev, elem) => prev + elem);
    final avatarColor = Colors.primaries[nameHash % Colors.primaries.length];

    final sentStatuses = ref.watch(sentRequestStatusesProvider);
    final friendsState = ref.watch(friendsListProvider);

    // Determine button state
    String? sentStatus;
    bool isFriend = false;

    sentStatuses.whenData((statuses) {
      sentStatus = statuses[match.profile.id];
    });

    friendsState.whenData((friends) {
      isFriend = friends.any((f) => f.id == match.profile.id);
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Avatar, Name, Major
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: avatarColor.withAlpha(25),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.profile.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.profile.major,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Profile info row: Semester
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEMESTER AKADEMIK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Semester ${match.profile.semester}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shared Courses section
            if (match.sharedCourses.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Shared Courses (${match.sharedCount})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.sharedCourses.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // All Courses section
            const Text(
              'All Taken Courses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (match.allCourses.isEmpty)
              const Text(
                'No courses registered yet.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.allCourses.map((c) {
                  final isShared = match.sharedCourses.contains(c);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isShared ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isShared ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isShared ? AppColors.success : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            // Call to Action
            _buildActionButton(context, ref, isFriend, sentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, bool isFriend, String? sentStatus) {
    if (isFriend || sentStatus == 'accepted') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: const Text('Already Study Mates ✓', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (sentStatus == 'pending') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: null,
        icon: const Icon(Icons.hourglass_top),
        label: const Text('Invitation Sent', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    // Default: can send invite
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () async {
        try {
          await ref.read(friendRepositoryProvider).sendFriendRequest(match.profile.id);
          ref.invalidate(sentRequestStatusesProvider);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invitation sent to ${match.profile.fullName}!'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send invitation: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Undang Belajar Bersama', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
