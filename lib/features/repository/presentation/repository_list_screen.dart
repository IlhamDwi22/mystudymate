import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/repository_file.dart';
import '../providers/repository_provider.dart';
import 'repository_detail_screen.dart';
import 'upload_repository_screen.dart';

class RepositoryListScreen extends ConsumerStatefulWidget {
  const RepositoryListScreen({super.key});

  @override
  ConsumerState<RepositoryListScreen> createState() => _RepositoryListScreenState();
}

class _RepositoryListScreenState extends ConsumerState<RepositoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


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
    final filesState = ref.watch(repositoryFilesProvider);

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
          'Academic Repository',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: const Icon(Icons.cloud_upload_outlined, size: 22),
        label: const Text(
          'Upload File',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadRepositoryScreen(),
            ),
          ).then((uploaded) {
            if (uploaded == true) {
              ref.read(repositoryFilesProvider.notifier).loadRepositoryFiles();
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
                    hintText: 'Cari materi kuliah...',
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



              // Files Listing
              Expanded(
                child: filesState.when(
                  data: (files) {
                    // Filter matching queries
                    final filteredFiles = files.where((f) {
                      final matchesSearch = f.title.toLowerCase().contains(_searchQuery) ||
                          f.courseName.toLowerCase().contains(_searchQuery);
                      
                      return matchesSearch;
                    }).toList();

                    if (filteredFiles.isEmpty) {
                      return _buildEmptyState(files.isEmpty);
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(repositoryFilesProvider.notifier).loadRepositoryFiles(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filteredFiles.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return _buildFileCard(context, file);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                        const SizedBox(height: 16),
                        Text('Gagal memuat materi: $err', style: const TextStyle(color: AppColors.textLight)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(repositoryFilesProvider.notifier).loadRepositoryFiles(),
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

  Widget _buildFileCard(BuildContext context, RepositoryFile file) {
    // Generate dates mapping to "2 hours ago", "Yesterday", etc.
    String timeText = 'Today';
    final diff = DateTime.now().difference(file.uploadedAt);
    if (diff.inMinutes < 60) {
      timeText = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeText = '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      timeText = 'Yesterday';
    } else {
      timeText = '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}';
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
                builder: (context) => RepositoryDetailScreen(file: file),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Red/Orange PDF Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // File metadata details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.courseName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Oleh: ${file.uploaderName ?? "Pengguna"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textLight, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textLight,
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
                color: AppColors.primary.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isDatabaseEmpty ? 'Repository Masih Kosong' : 'Materi Tidak Ditemukan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDatabaseEmpty
                  ? 'Mulai unggah berkas PDF modul kuliah atau ringkasan materi untuk membagikannya ke teman belajar.'
                  : 'Coba sesuaikan kata kunci pencarian Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
