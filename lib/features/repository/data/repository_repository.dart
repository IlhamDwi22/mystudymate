import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/repository_file.dart';

class RepositoryRepository {
  final SupabaseClient _supabase;

  RepositoryRepository(this._supabase);

  /// Fetch all repository files with uploader profiles
  Future<List<RepositoryFile>> getRepositoryFiles() async {
    debugPrint('[RepositoryRepository] getRepositoryFiles called');

    try {
      // Try fetching with profiles JOIN first
      final List<dynamic> response = await _supabase
          .from('repository_files')
          .select('*, profiles(full_name)')
          .order('uploaded_at', ascending: false);

      debugPrint('[RepositoryRepository] getRepositoryFiles success: ${response.length} rows');
      return response.map((row) => RepositoryFile.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[RepositoryRepository] getRepositoryFiles with JOIN failed: $e');

      // Fallback: query without the profiles JOIN
      try {
        final List<dynamic> response = await _supabase
            .from('repository_files')
            .select()
            .order('uploaded_at', ascending: false);

        debugPrint('[RepositoryRepository] getRepositoryFiles (no JOIN) success: ${response.length} rows');
        return response.map((row) => RepositoryFile.fromJson(row)).toList();
      } catch (e2) {
        debugPrint('[RepositoryRepository] getRepositoryFiles completely failed: $e2');
        rethrow;
      }
    }
  }

  /// Upload file to Supabase storage and insert metadata row to DB
  Future<RepositoryFile> uploadRepositoryFile({
    required String title,
    required String courseName,
    required String localPath,
    required Uint8List? fileBytes,
    required String fileName,
    required String userId,
  }) async {
    debugPrint('[RepositoryRepository] uploadRepositoryFile called:');
    debugPrint('  title="$title"');
    debugPrint('  course="$courseName"');
    debugPrint('  fileName="$fileName"');
    debugPrint('  localPath="$localPath"');
    debugPrint('  fileBytes=${fileBytes != null ? "${fileBytes.length} bytes" : "null"}');
    debugPrint('  userId="$userId"');

    // 1. Generate unique file path in bucket
    final String ext = fileName.split('.').last.toLowerCase();
    final String storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    debugPrint('[RepositoryRepository] storagePath: $storagePath');

    // 2. Upload file to 'repository' bucket
    try {
      if (kIsWeb) {
        if (fileBytes == null) throw Exception('File bytes are required on Web.');
        debugPrint('[RepositoryRepository] Uploading via uploadBinary (Web)...');
        await _supabase.storage.from('repository').uploadBinary(storagePath, fileBytes);
      } else {
        // On mobile/desktop, prefer fileBytes if available (file_picker provides them)
        // because localPath can be empty or point to a cached temp file
        if (fileBytes != null && fileBytes.isNotEmpty) {
          debugPrint('[RepositoryRepository] Uploading via uploadBinary (mobile with bytes)...');
          await _supabase.storage.from('repository').uploadBinary(storagePath, fileBytes);
        } else if (localPath.isNotEmpty) {
          final file = File(localPath);
          if (!await file.exists()) {
            throw Exception('File not found at path: $localPath');
          }
          debugPrint('[RepositoryRepository] Uploading via upload (File path)...');
          await _supabase.storage.from('repository').upload(storagePath, file);
        } else {
          throw Exception('No file data available. Both fileBytes and localPath are empty.');
        }
      }
      debugPrint('[RepositoryRepository] Storage upload SUCCESS');
    } catch (e) {
      debugPrint('[RepositoryRepository] Storage upload FAILED: $e');
      rethrow;
    }

    // 3. Insert metadata row into table 'repository_files'
    try {
      debugPrint('[RepositoryRepository] Inserting metadata row...');
      final Map<String, dynamic> row = await _supabase
          .from('repository_files')
          .insert({
            'user_id': userId,
            'title': title,
            'course_name': courseName,
            'file_path': storagePath,
          })
          .select('*, profiles(full_name)')
          .single();

      debugPrint('[RepositoryRepository] DB insert SUCCESS: $row');
      return RepositoryFile.fromJson(row);
    } catch (e) {
      debugPrint('[RepositoryRepository] DB insert with JOIN failed: $e');
      
      // Fallback: try insert without the profiles JOIN in select
      try {
        final Map<String, dynamic> row = await _supabase
            .from('repository_files')
            .insert({
              'user_id': userId,
              'title': title,
              'course_name': courseName,
              'file_path': storagePath,
            })
            .select()
            .single();

        debugPrint('[RepositoryRepository] DB insert (no JOIN) SUCCESS: $row');
        return RepositoryFile.fromJson(row);
      } catch (e2) {
        debugPrint('[RepositoryRepository] DB insert completely FAILED: $e2');
        // Clean up the uploaded storage file since DB insert failed
        try {
          await _supabase.storage.from('repository').remove([storagePath]);
          debugPrint('[RepositoryRepository] Cleaned up orphaned storage file');
        } catch (_) {}
        rethrow;
      }
    }
  }

  /// Delete file from database and storage
  Future<void> deleteRepositoryFile(String id, String storagePath) async {
    debugPrint('[RepositoryRepository] deleteRepositoryFile: id="$id", path="$storagePath"');

    // Delete DB row
    await _supabase.from('repository_files').delete().eq('id', id);
    debugPrint('[RepositoryRepository] DB row deleted');

    // Delete storage file (best-effort)
    try {
      await _supabase.storage.from('repository').remove([storagePath]);
      debugPrint('[RepositoryRepository] Storage file deleted');
    } catch (e) {
      debugPrint('[RepositoryRepository] Failed to delete storage file (non-critical): $e');
    }
  }

  /// Get signed download URL (valid for 60 seconds) with fallback to public URL
  Future<String> getDownloadUrl(String storagePath) async {
    debugPrint('[RepositoryRepository] getDownloadUrl: path="$storagePath"');
    try {
      final url = await _supabase.storage.from('repository').createSignedUrl(storagePath, 60);
      debugPrint('[RepositoryRepository] Signed URL created');
      return url;
    } catch (e) {
      debugPrint('[RepositoryRepository] Signed URL failed: $e, trying public URL...');
      try {
        return _supabase.storage.from('repository').getPublicUrl(storagePath);
      } catch (e2) {
        debugPrint('[RepositoryRepository] Public URL also failed: $e2');
        rethrow;
      }
    }
  }
}

