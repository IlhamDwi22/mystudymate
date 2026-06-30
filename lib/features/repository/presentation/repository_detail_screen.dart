import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/repository_file.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/repository_provider.dart';

class RepositoryDetailScreen extends ConsumerStatefulWidget {
  final RepositoryFile file;

  const RepositoryDetailScreen({
    super.key,
    required this.file,
  });

  @override
  ConsumerState<RepositoryDetailScreen> createState() => _RepositoryDetailScreenState();
}

class _RepositoryDetailScreenState extends ConsumerState<RepositoryDetailScreen> {
  bool _isDownloading = false;
  bool _isDeleting = false;

  void _downloadFile() async {
    setState(() {
      _isDownloading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(repositoryRepositoryProvider);
      final downloadUrl = await repository.getDownloadUrl(widget.file.filePath);
      final Uri uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka tautan unduh';
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh berkas: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _deleteFile() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Apakah Anda yakin ingin menghapus materi kuliah ini dari repository?'),
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
        await ref.read(repositoryFilesProvider.notifier).deleteFile(
              widget.file.id,
              widget.file.filePath,
            );
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Berkas berhasil dihapus dari repository!'),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        setState(() {
          _isDeleting = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus berkas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isUploader = currentUserId == widget.file.userId;

    final createdDateText = '${widget.file.uploadedAt.day}/${widget.file.uploadedAt.month}/${widget.file.uploadedAt.year}';

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
          'Detail Materi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Document Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFFEF4444),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.file.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.file.courseName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Metadata Details Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.description_outlined,
                      label: 'Nama Berkas',
                      value: widget.file.filePath.split('/').last,
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'Pengunggah',
                      value: widget.file.uploaderName ?? 'Pengguna',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 24),
                    _buildDetailRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Tanggal Unggah',
                      value: createdDateText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Download Button
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
                onPressed: _isDownloading || _isDeleting ? null : _downloadFile,
                icon: _isDownloading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: const Text(
                  'Unduh PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Delete Button (only if owner)
              if (isUploader)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isDownloading || _isDeleting ? null : _deleteFile,
                  icon: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text(
                    'Hapus Materi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textLight, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
