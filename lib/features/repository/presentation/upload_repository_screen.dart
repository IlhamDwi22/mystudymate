import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/repository_provider.dart';

class UploadRepositoryScreen extends ConsumerStatefulWidget {
  const UploadRepositoryScreen({super.key});

  @override
  ConsumerState<UploadRepositoryScreen> createState() => _UploadRepositoryScreenState();
}

class _UploadRepositoryScreenState extends ConsumerState<UploadRepositoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String? _selectedCourse;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  
  final List<String> _courses = [
    'Database System',
    'Artificial Intelligence',
    'Technopreneurship',
    'Project Based Learning',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          // Pre-fill title with file name without extension if title is empty
          if (_titleController.text.trim().isEmpty) {
            final name = _selectedFile!.name;
            final dotIdx = name.lastIndexOf('.');
            _titleController.text = dotIdx != -1 ? name.substring(0, dotIdx) : name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _upload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih berkas PDF terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isUploading = true;
      });

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await ref.read(repositoryFilesProvider.notifier).uploadFile(
          title: _titleController.text.trim(),
          courseName: _selectedCourse!,
          localPath: _selectedFile!.path ?? '',
          fileBytes: _selectedFile!.bytes,
          fileName: _selectedFile!.name,
        );

        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Berkas berhasil diunggah!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah berkas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Materi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. File Picker Box Area
                const Text(
                  'Pilih Berkas PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isUploading ? null : _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile == null ? 'Pilih berkas PDF dari penyimpanan Anda' : _selectedFile!.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedFile == null ? FontWeight.w500 : FontWeight.bold,
                            color: _selectedFile == null ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_selectedFile != null)
                          Text(
                            'Ukuran: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          )
                        else
                          const Text(
                            'Batas ukuran maks: 10 MB (Format: PDF saja)',
                            style: TextStyle(fontSize: 11, color: AppColors.textLight),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Title/Name Field
                const Text(
                  'Judul Materi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama/judul materi kuliah...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul materi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Course Field Dropdown
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    fillColor: Color(0xFFF8FAFC),
                    filled: true,
                  ),
                  value: _selectedCourse,
                  hint: const Text('Pilih Mata Kuliah'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course),
                    );
                  }).toList(),
                  onChanged: _isUploading
                      ? null
                      : (val) {
                          setState(() {
                            _selectedCourse = val;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Silakan pilih mata kuliah terkait';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 4. Action Buttons
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
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Unggah Berkas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
