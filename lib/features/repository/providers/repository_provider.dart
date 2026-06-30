import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/repository_repository.dart';
import '../../../shared/models/repository_file.dart';

final repositoryRepositoryProvider = Provider<RepositoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RepositoryRepository(client);
});

class RepositoryFilesNotifier extends StateNotifier<AsyncValue<List<RepositoryFile>>> {
  final RepositoryRepository _repository;
  final String? _userId;

  RepositoryFilesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await loadRepositoryFiles();
  }

  Future<void> loadRepositoryFiles() async {
    debugPrint('[RepositoryFilesNotifier] loadRepositoryFiles starting');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final list = await _repository.getRepositoryFiles();
      return list;
    });
  }

  Future<void> uploadFile({
    required String title,
    required String courseName,
    required String localPath,
    required Uint8List? fileBytes,
    required String fileName,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated.');

    debugPrint('[RepositoryFilesNotifier] uploadFile starting: title="$title"');

    // Perform the upload — let errors propagate to the caller so UI can show them
    await _repository.uploadRepositoryFile(
      title: title,
      courseName: courseName,
      localPath: localPath,
      fileBytes: fileBytes,
      fileName: fileName,
      userId: userId,
    );

    // After successful upload, reload the list
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getRepositoryFiles();
    });
  }

  Future<void> deleteFile(String id, String storagePath) async {
    debugPrint('[RepositoryFilesNotifier] deleteFile starting: id="$id"');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteRepositoryFile(id, storagePath);
      return await _repository.getRepositoryFiles();
    });
  }
}

final repositoryFilesProvider = StateNotifierProvider<RepositoryFilesNotifier, AsyncValue<List<RepositoryFile>>>((ref) {
  final repository = ref.watch(repositoryRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return RepositoryFilesNotifier(repository, userId);
});
