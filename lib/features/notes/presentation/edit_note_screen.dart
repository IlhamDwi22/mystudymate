import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/note.dart';
import '../providers/notes_provider.dart';

class EditNoteScreen extends ConsumerStatefulWidget {
  final Note? note; // null for Create Mode, non-null for Edit Mode

  const EditNoteScreen({
    super.key,
    this.note,
  });

  @override
  ConsumerState<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends ConsumerState<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCourse;
  String? _customCourse;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _courses = [
    'Database System',
    'Artificial Intelligence',
    'Technopreneurship',
    'Project Based Learning',
    'Lainnya (Ketik sendiri)',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    
    final noteCourse = widget.note?.courseName;
    if (noteCourse != null) {
      if (_courses.contains(noteCourse)) {
        _selectedCourse = noteCourse;
      } else {
        _selectedCourse = 'Lainnya (Ketik sendiri)';
        _customCourse = noteCourse;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final finalCourse = _selectedCourse == 'Lainnya (Ketik sendiri)' ? _customCourse! : _selectedCourse!;
        
        if (widget.note == null) {
          // Create Mode
          await ref.read(notesProvider.notifier).createNote(
                title: _titleController.text.trim(),
                courseName: finalCourse,
                content: _contentController.text.trim(),
              );
        } else {
          // Edit Mode
          await ref.read(notesProvider.notifier).updateNote(
                id: widget.note!.id,
                title: _titleController.text.trim(),
                courseName: finalCourse,
                content: _contentController.text.trim(),
              );
        }

        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(widget.note == null ? 'Catatan berhasil disimpan!' : 'Catatan berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan catatan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _deleteNote() async {
    if (widget.note == null) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan kuliah ini?'),
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
      setState(() {
        _isDeleting = true;
      });

      try {
        await ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil dihapus!'),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        setState(() {
          _isDeleting = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus catatan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.note != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: _isSaving || _isDeleting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit Catatan' : 'Tambah Catatan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _isSaving || _isDeleting ? null : _deleteNote,
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            onPressed: _isSaving || _isDeleting ? null : _saveNote,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title Input
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSaving && !_isDeleting,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Judul catatan...',
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul catatan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 32),

                // 2. Course Dropdown Selector
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    fillColor: Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: _selectedCourse,
                  hint: const Text('Pilih Mata Kuliah'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: _isSaving || _isDeleting
                      ? null
                      : (val) {
                          setState(() {
                            _selectedCourse = val;
                            if (val != 'Lainnya (Ketik sendiri)') _customCourse = null;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Silakan hubungkan catatan dengan mata kuliah';
                    }
                    return null;
                  },
                ),
                if (_selectedCourse == 'Lainnya (Ketik sendiri)') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _customCourse,
                    enabled: !_isSaving && !_isDeleting,
                    decoration: const InputDecoration(
                      hintText: 'Ketik nama mata kuliah...',
                      fillColor: Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => _customCourse = val,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Mata kuliah tidak boleh kosong' : null,
                  ),
                ],
                const SizedBox(height: 20),

                // 3. Content Text Area
                Expanded(
                  child: TextFormField(
                    controller: _contentController,
                    enabled: !_isSaving && !_isDeleting,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textDark),
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Mulai menulis catatan Anda di sini...',
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Isi catatan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
