import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/note.dart';
import '../providers/notes_provider.dart';
import 'edit_note_screen.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCourse;

  final List<String> _courses = [
    'Database System',
    'Artificial Intelligence',
    'Technopreneurship',
    'Project Based Learning',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);

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
          'Catatan Kuliah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD97706), // warm amber
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 24),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditNoteScreen(),
            ),
          ).then((saved) {
            if (saved == true) {
              ref.read(notesProvider.notifier).loadNotes();
            }
          });
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textLight),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Course filter dropdown selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCourse,
                    hint: const Text('Filter berdasarkan Mata Kuliah', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Mata Kuliah', style: TextStyle(fontSize: 13))),
                      ..._courses.map((course) {
                        return DropdownMenuItem(value: course, child: Text(course, style: const TextStyle(fontSize: 13)));
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCourse = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes list
              Expanded(
                child: notesState.when(
                  data: (notes) {
                    final filteredNotes = notes.where((n) {
                      final matchesSearch = n.title.toLowerCase().contains(_searchQuery) ||
                          n.content.toLowerCase().contains(_searchQuery);
                      final matchesCourse = _selectedCourse == null || n.courseName == _selectedCourse;
                      return matchesSearch && matchesCourse;
                    }).toList();

                    if (filteredNotes.isEmpty) {
                      return _buildEmptyState(notes.isEmpty);
                    }

                    return RefreshIndicator(
                      color: const Color(0xFFD97706),
                      onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filteredNotes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _buildNoteCard(context, note);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD97706)),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                        const SizedBox(height: 16),
                        Text('Gagal memuat catatan: $err', style: const TextStyle(color: AppColors.textLight)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final dateText = '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}';
    
    // Truncate content preview
    String preview = note.content;
    if (preview.length > 80) {
      preview = '${preview.substring(0, 80)}...';
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
                builder: (context) => EditNoteScreen(note: note),
              ),
            ).then((saved) {
              if (saved == true) {
                ref.read(notesProvider.notifier).loadNotes();
              }
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
                    // Course badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        note.courseName,
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preview,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDatabaseEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                size: 80,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isDatabaseEmpty ? 'Belum Ada Catatan' : 'Catatan Tidak Ditemukan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tulis ringkasan mata kuliah pribadi untuk mempermudah belajar mandiri maupun persiapan ujian.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
