import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/course_provider.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/user_course.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final coursesState = ref.watch(userCoursesProvider);

    // Listen to profile errors and display a toast/snackbar
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Icon(
          Icons.account_circle_outlined,
          color: AppColors.primary,
          size: 28,
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textLight),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No profile found. Please register or re-login.'),
            );
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Avatar & Name Header
                _buildProfileHeader(context, ref, profile),
                const SizedBox(height: 24),

                // 2. Academic Profile Card
                _buildAcademicCard(profile),
                const SizedBox(height: 24),

                // 3. My Courses Section
                _buildCoursesSection(context, ref, coursesState),
                const SizedBox(height: 24),

                // 4. Menu Settings Options Card
                _buildMenuOptionsCard(context, ref, profile),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat profil',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Profile Header ---
  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, UserProfile profile) {
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email ?? '';
    
    // Generates initials from full name
    final initials = profile.fullName.isNotEmpty
        ? profile.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(25),
                  width: 4,
                ),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primary.withAlpha(15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showEditProfileSheet(context, ref, profile),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // --- Academic Profile Card ---
  Widget _buildAcademicCard(UserProfile profile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ACADEMIC PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program Study',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.major.isNotEmpty ? profile.major : '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semester ${profile.semester}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Courses Section ---
  Widget _buildCoursesSection(
      BuildContext context, WidgetRef ref, AsyncValue<List<UserCourse>> state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () => _showManageCoursesSheet(context, ref),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        state.when(
          data: (courses) {
            if (courses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Belum ada mata kuliah.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showManageCoursesSheet(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Mata Kuliah'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Display up to 4 courses in the home profile view
            final displayedCourses = courses.take(4).toList();

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: displayedCourses.map((course) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F1FF), // Soft blue chip bg
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCourseIcon(course.courseName),
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          error: (err, stack) => Text(
            'Gagal memuat mata kuliah: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  // --- Menu Options Card ---
  Widget _buildMenuOptionsCard(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              iconBgColor: const Color(0xFFEBF3FF),
              iconColor: AppColors.primary,
              title: 'Edit Profile',
              onTap: () => _showEditProfileSheet(context, ref, profile),
            ),
            Divider(height: 1, color: Colors.grey.shade100, indent: 64),
            _buildMenuItem(
              icon: Icons.info_outline,
              iconBgColor: const Color(0xFFEBF3FF),
              iconColor: AppColors.primary,
              title: 'About App',
              onTap: () => _showAboutAppDialog(context),
            ),
            Divider(height: 1, color: Colors.grey.shade100, indent: 64),
            _buildMenuItem(
              icon: Icons.lock_outline,
              iconBgColor: const Color(0xFFEBF3FF),
              iconColor: AppColors.primary,
              title: 'Privacy Policy',
              onTap: () => _showPrivacyPolicyDialog(context),
            ),
            Divider(height: 1, color: Colors.grey.shade100, indent: 64),
            _buildMenuItem(
              icon: Icons.logout_outlined,
              iconBgColor: const Color(0xFFFFECEB),
              iconColor: AppColors.error,
              title: 'Logout',
              titleColor: AppColors.error,
              trailingColor: AppColors.error,
              onTap: () => _showLogoutConfirmation(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    Color titleColor = AppColors.textDark,
    Color trailingColor = Colors.grey,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: trailingColor.withAlpha(180),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  // --- Helper to pick Course Icon ---
  IconData _getCourseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('data') || lower.contains('database') || lower.contains('basis data')) {
      return Icons.storage_outlined;
    } else if (lower.contains('mobile') ||
        lower.contains('android') ||
        lower.contains('ios') ||
        lower.contains('pemrograman mobile')) {
      return Icons.phone_android_outlined;
    } else if (lower.contains('intelligence') ||
        lower.contains('ai') ||
        lower.contains('artificial') ||
        lower.contains('kecerdasan buatan')) {
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

  // --- Show Edit Profile Bottom Sheet ---
  void _showEditProfileSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
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
          child: _EditProfileBottomSheet(profile: profile),
        );
      },
    );
  }

  // --- Show Manage Courses Bottom Sheet ---
  void _showManageCoursesSheet(BuildContext context, WidgetRef ref) {
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
          child: const _ManageCoursesBottomSheet(),
        );
      },
    );
  }

  // --- Settings Dialog ---
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan'),
        content: const Text('Pengaturan aplikasi saat ini belum tersedia di versi MVP ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // --- About App Dialog ---
  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('MyStudyMate'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MyStudyMate v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Aplikasi manajemen kelompok belajar, akademik repository, dan pelacakan tugas mahasiswa untuk proyek Technopreneurship.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // --- Privacy Policy Dialog ---
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
          child: Text(
            'Kami menghormati privasi Anda. Data Anda disimpan dengan aman di Supabase dan hanya digunakan untuk keperluan akademis Anda di aplikasi MyStudyMate.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  // --- Logout Confirmation Dialog ---
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// EDIT PROFILE BOTTOM SHEET WIDGET
// ==========================================
class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _EditProfileBottomSheet({required this.profile});

  @override
  ConsumerState<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedMajor;
  String? _customMajor;
  String? _selectedSemester;
  String? _customSemester;
  bool _isSaving = false;

  final List<String> _majors = [
    'D3 Teknik Informatika',
    'D4 Teknik Rekayasa Komputer',
    'D3 Akuntansi',
    'D4 Administrasi Bisnis',
    'Lainnya (Ketik sendiri)',
  ];

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8', 'Lainnya (Ketik sendiri)'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    
    if (_majors.contains(widget.profile.major)) {
      _selectedMajor = widget.profile.major;
    } else if (widget.profile.major.isNotEmpty) {
      _selectedMajor = 'Lainnya (Ketik sendiri)';
      _customMajor = widget.profile.major;
    }

    final semStr = widget.profile.semester.toString();
    if (_semesters.contains(semStr)) {
      _selectedSemester = semStr;
    } else if (widget.profile.semester > 0) {
      _selectedSemester = 'Lainnya (Ketik sendiri)';
      _customSemester = semStr;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      try {
        final finalMajor = _selectedMajor == 'Lainnya (Ketik sendiri)' ? _customMajor! : _selectedMajor!;
        final finalSemesterStr = _selectedSemester == 'Lainnya (Ketik sendiri)' ? _customSemester! : _selectedSemester!;
        final finalSemester = int.tryParse(finalSemesterStr) ?? 1;

        await ref.read(userProfileProvider.notifier).updateProfile(
              fullName: _nameController.text.trim(),
              major: finalMajor,
              semester: finalSemester,
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui profil: $err'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // Name field
            const Text(
              'Nama Lengkap',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama lengkap',
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // Major field
            const Text(
              'Program Studi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Pilih program studi',
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              value: _selectedMajor,
              items: _majors.map((major) {
                return DropdownMenuItem(
                  value: major,
                  child: Text(major),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedMajor = val;
                if (val != 'Lainnya (Ketik sendiri)') _customMajor = null;
              }),
              validator: (val) => val == null ? 'Pilih program studi' : null,
            ),
            if (_selectedMajor == 'Lainnya (Ketik sendiri)') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _customMajor,
                decoration: InputDecoration(
                  hintText: 'Ketik program studi Anda...',
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => _customMajor = val,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Harap ketik program studi' : null,
              ),
            ],
            const SizedBox(height: 16),

            // Semester field
            const Text(
              'Semester',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Pilih semester',
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              value: _selectedSemester,
              items: _semesters.map((sem) {
                return DropdownMenuItem(
                  value: sem,
                  child: Text(sem == 'Lainnya (Ketik sendiri)' ? sem : 'Semester $sem'),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedSemester = val;
                if (val != 'Lainnya (Ketik sendiri)') _customSemester = null;
              }),
              validator: (val) => val == null ? 'Pilih semester' : null,
            ),
            if (_selectedSemester == 'Lainnya (Ketik sendiri)') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _customSemester,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ketik semester (Angka)...',
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => _customSemester = val,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Harap ketik semester' : null,
              ),
            ],
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MANAGE COURSES BOTTOM SHEET WIDGET
// ==========================================
class _ManageCoursesBottomSheet extends ConsumerStatefulWidget {
  const _ManageCoursesBottomSheet();

  @override
  ConsumerState<_ManageCoursesBottomSheet> createState() => _ManageCoursesBottomSheetState();
}

class _ManageCoursesBottomSheetState extends ConsumerState<_ManageCoursesBottomSheet> {
  final _addFormKey = GlobalKey<FormState>();
  final _customCourseController = TextEditingController();
  String? _selectedCourse;
  bool _isAdding = false;
  
  final List<String> _predefinedCourses = [
    'Kecerdasan Buatan',
    'Basis Data',
    'Pemrograman Mobile',
    'Jaringan Komputer',
    'Pemrograman Web',
    'Lainnya (Ketik sendiri)',
  ];

  @override
  void dispose() {
    _customCourseController.dispose();
    super.dispose();
  }

  void _addCourse() async {
    if (_addFormKey.currentState?.validate() ?? false) {
      setState(() => _isAdding = true);
      try {
        final courseName = _selectedCourse == 'Lainnya (Ketik sendiri)' 
            ? _customCourseController.text.trim() 
            : _selectedCourse!;
        await ref.read(userCoursesProvider.notifier).addCourse(courseName);
        _customCourseController.clear();
        setState(() => _selectedCourse = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mata kuliah "$courseName" ditambahkan'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan: $err'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isAdding = false);
      }
    }
  }

  void _deleteCourse(UserCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mata Kuliah'),
        content: Text('Apakah Anda yakin ingin menghapus "${course.courseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(userCoursesProvider.notifier).deleteCourse(course.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mata kuliah "${course.courseName}" berhasil dihapus'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $err'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(userCoursesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Form to add course
          Form(
            key: _addFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Pilih mata kuliah',
                    filled: true,
                    fillColor: const Color(0xFFF0F4FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  value: _selectedCourse,
                  items: _predefinedCourses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedCourse = val;
                    if (val != 'Lainnya (Ketik sendiri)') _customCourseController.clear();
                  }),
                  validator: (val) => val == null ? 'Silakan pilih mata kuliah' : null,
                ),
                if (_selectedCourse == 'Lainnya (Ketik sendiri)') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customCourseController,
                    decoration: InputDecoration(
                      hintText: 'Ketik nama mata kuliah...',
                      filled: true,
                      fillColor: const Color(0xFFF0F4FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Nama mata kuliah tidak boleh kosong'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isAdding ? null : _addCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Tambah Mata Kuliah',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // List of courses
          Expanded(
            child: coursesState.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('Belum ada mata kuliah yang didaftarkan.'),
                  );
                }
                return ListView.separated(
                  itemCount: courses.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getCourseIcon(course.courseName),
                        color: AppColors.primary,
                      ),
                      title: Text(
                        course.courseName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _deleteCourse(course),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (err, stack) => Center(
                child: Text('Gagal memuat mata kuliah: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper to pick Course Icon ---
  IconData _getCourseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('data') || lower.contains('database') || lower.contains('basis data')) {
      return Icons.storage_outlined;
    } else if (lower.contains('mobile') ||
        lower.contains('android') ||
        lower.contains('ios') ||
        lower.contains('pemrograman mobile')) {
      return Icons.phone_android_outlined;
    } else if (lower.contains('intelligence') ||
        lower.contains('ai') ||
        lower.contains('artificial') ||
        lower.contains('kecerdasan buatan')) {
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
}
