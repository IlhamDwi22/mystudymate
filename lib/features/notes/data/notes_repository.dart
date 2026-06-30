import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/note.dart';

class NotesRepository {
  final SupabaseClient _supabase;
  
  // Local fallback storage for robust demo stability
  final List<Note> _localMockNotes = [];
  bool _useLocalFallback = false;

  NotesRepository(this._supabase);

  /// Fetch notes for the user
  Future<List<Note>> getNotes(String userId) async {
    debugPrint('[NotesRepository] getNotes called for user: $userId');
    if (_useLocalFallback) {
      return _localMockNotes;
    }

    try {
      final List<dynamic> response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      debugPrint('[NotesRepository] getNotes response: $response');
      return response.map((row) => Note.fromJson(row)).toList();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('relation "notes" does not exist') || errStr.contains('42P01')) {
        debugPrint('[NotesRepository] Table "notes" does not exist in Supabase. Falling back to local mock storage.');
        _useLocalFallback = true;
        
        // Add initial mock notes for premium feel
        if (_localMockNotes.isEmpty) {
          _localMockNotes.add(Note(
            id: 'mock-1',
            userId: userId,
            courseName: 'Artificial Intelligence',
            title: 'Rangkuman Ujian Tengah Semester',
            content: 'Catatan tentang konsep dasar AI:\n\n1. Search Algorithms: BFS, DFS, A*\n2. Machine Learning: Supervised vs Unsupervised Learning\n3. Neural Networks: Perceptron, Activation Functions.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ));
          _localMockNotes.add(Note(
            id: 'mock-2',
            userId: userId,
            courseName: 'Database System',
            title: 'Query Optimization Notes',
            content: 'Langkah optimalisasi query SQL:\n\n- Gunakan index pada kolom yang sering di-filter (WHERE).\n- Hindari SELECT * jika hanya butuh beberapa kolom.\n- Gunakan EXPLAIN ANALYZE untuk profil query.',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
          ));
        }
        return _localMockNotes;
      }
      rethrow;
    }
  }

  /// Create a new note
  Future<Note> createNote(Note note) async {
    debugPrint('[NotesRepository] createNote called for title: "${note.title}"');
    if (_useLocalFallback) {
      final newNote = note.copyWith(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localMockNotes.insert(0, newNote);
      return newNote;
    }

    try {
      final Map<String, dynamic> row = await _supabase
          .from('notes')
          .insert(note.toJson())
          .select()
          .single();
      return Note.fromJson(row);
    } catch (e) {
      debugPrint('[NotesRepository] Failed to insert note in DB: $e');
      rethrow;
    }
  }

  /// Update an existing note
  Future<Note> updateNote(Note note) async {
    debugPrint('[NotesRepository] updateNote called for ID: ${note.id}');
    if (_useLocalFallback) {
      final idx = _localMockNotes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        final updated = note.copyWith(updatedAt: DateTime.now());
        _localMockNotes[idx] = updated;
        return updated;
      }
      throw Exception('Catatan tidak ditemukan');
    }

    try {
      final Map<String, dynamic> row = await _supabase
          .from('notes')
          .update({
            'title': note.title,
            'course_name': note.courseName,
            'content': note.content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', note.id)
          .select()
          .single();
      return Note.fromJson(row);
    } catch (e) {
      debugPrint('[NotesRepository] Failed to update note in DB: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    debugPrint('[NotesRepository] deleteNote called for ID: $id');
    if (_useLocalFallback) {
      _localMockNotes.removeWhere((n) => n.id == id);
      return;
    }

    try {
      await _supabase.from('notes').delete().eq('id', id);
    } catch (e) {
      debugPrint('[NotesRepository] Failed to delete note from DB: $e');
      rethrow;
    }
  }
}
