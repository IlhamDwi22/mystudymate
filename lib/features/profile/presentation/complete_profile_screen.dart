import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMajor;
  String? _customMajor;
  String? _selectedSemester;
  String? _customSemester;

  final List<String> _majors = [
    'D3 Teknik Informatika',
    'D4 Teknik Rekayasa Komputer',
    'D3 Akuntansi',
    'D4 Administrasi Bisnis',
    'Lainnya (Ketik sendiri)',
  ];

  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8', 'Lainnya (Ketik sendiri)'];

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final majorToSave = _selectedMajor == 'Lainnya (Ketik sendiri)' ? _customMajor! : _selectedMajor!;
      final semesterToSave = _selectedSemester == 'Lainnya (Ketik sendiri)' ? _customSemester! : _selectedSemester!;
      final semInt = int.tryParse(semesterToSave) ?? 1;

      await ref
          .read(userProfileProvider.notifier)
          .completeProfile(
            major: majorToSave,
            semester: semInt,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final isLoading = profileState.isLoading;

    ref.listen<AsyncValue<dynamic>>(userProfileProvider, (previous, next) {
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Gradient Background behind the top portion
            Container(
              height: 290,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4F80F6), Color(0xFF0058BE)],
                ),
              ),
            ),
            // Main content column
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar (placed inside SafeArea for padding)
                SafeArea(
                  bottom: false,
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Back Arrow Button (performs logout to allow users to switch accounts)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Keluar'),
                                      content: const Text(
                                        'Apakah Anda ingin keluar dari akun Anda?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Keluar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .signOut();
                                  }
                                },
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Academic Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Overlapping white container for the profile completion form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 36.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Complete Your Academic Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This helps us personalize your study experience and recommend resources tailored to your curriculum.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Dropdown 1 Label
                        Text(
                          'Program of Study',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select your major',
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                          ),
                          value: _selectedMajor,
                          items: _majors.map((major) {
                            return DropdownMenuItem(
                              value: major,
                              child: Text(major),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (val) =>
                                    setState(() {
                                      _selectedMajor = val;
                                      if (val != 'Lainnya (Ketik sendiri)') _customMajor = null;
                                    }),
                          validator: (val) => val == null
                              ? 'Pilih program studi Anda'
                              : null,
                        ),
                        if (_selectedMajor == 'Lainnya (Ketik sendiri)') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Ketik program studi Anda...',
                              filled: true,
                              fillColor: const Color(0xFFF0F4FF),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onChanged: (val) => _customMajor = val,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Harap ketik program studi' : null,
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Dropdown 2 Label
                        Text(
                          'Current Semester',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select semester',
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                          ),
                          value: _selectedSemester,
                          items: _semesters.map((semester) {
                            return DropdownMenuItem(
                              value: semester,
                              child: Text(semester == 'Lainnya (Ketik sendiri)' ? semester : 'Semester $semester'),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (val) =>
                                    setState(() {
                                      _selectedSemester = val;
                                      if (val != 'Lainnya (Ketik sendiri)') _customSemester = null;
                                    }),
                          validator: (val) => val == null
                              ? 'Pilih semester aktif Anda'
                              : null,
                        ),
                        if (_selectedSemester == 'Lainnya (Ketik sendiri)') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Ketik semester Anda (Angka)...',
                              filled: true,
                              fillColor: const Color(0xFFF0F4FF),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onChanged: (val) => _customSemester = val,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Harap ketik semester' : null,
                          ),
                        ],
                        const SizedBox(height: 36),
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Save and Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'You can update these details later in your settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
