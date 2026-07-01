import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/note.dart';

class NotesRepository {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  NotesRepository(this._supabase);

  String _localKey(String userId) => 'notes_$userId';

  /// Fetch notes for the user (tries Supabase, falls back to SharedPreferences)
  Future<List<Note>> getNotes(String userId) async {
    debugPrint('[NotesRepository] getNotes called for user: $userId');
    
    // 1. Try to fetch from Supabase
    try {
      final List<dynamic> response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      debugPrint('[NotesRepository] getNotes fetched from Supabase: ${response.length} items');
      final notes = response.map((row) => Note.fromJson(row)).toList();
      
      // Cache fetched notes locally
      await _saveLocalNotes(userId, notes);
      return notes;
    } catch (e) {
      debugPrint('[NotesRepository] Supabase getNotes failed ($e). Loading from local storage.');
      // 2. Fallback: Load from local SharedPreferences
      return await _loadLocalNotes(userId);
    }
  }

  /// Create a new note
  Future<Note> createNote(Note note) async {
    debugPrint('[NotesRepository] createNote called for title: "${note.title}"');
    
    // Generate UUID locally so we have the same ID offline and online
    final noteId = note.id.isEmpty ? _uuid.v4() : note.id;
    final newNote = note.copyWith(
      id: noteId,
      createdAt: note.createdAt == DateTime.fromMillisecondsSinceEpoch(0) ? DateTime.now() : note.createdAt,
      updatedAt: DateTime.now(),
    );

    // Save locally first for instant offline responsiveness
    final localNotes = await _loadLocalNotes(newNote.userId);
    localNotes.insert(0, newNote);
    await _saveLocalNotes(newNote.userId, localNotes);

    // Try to insert to Supabase
    try {
      await _supabase
          .from('notes')
          .insert({
            'id': newNote.id,
            'user_id': newNote.userId,
            'course_name': newNote.courseName,
            'title': newNote.title,
            'content': newNote.content,
            'created_at': newNote.createdAt.toIso8601String(),
            'updated_at': newNote.updatedAt.toIso8601String(),
          });
      debugPrint('[NotesRepository] createNote saved to Supabase');
      return newNote;
    } catch (e) {
      debugPrint('[NotesRepository] Supabase createNote failed ($e). Note remains saved locally.');
      // If offline, the note is still saved in SharedPreferences. We return it.
      return newNote;
    }
  }

  /// Update an existing note
  Future<Note> updateNote(Note note) async {
    debugPrint('[NotesRepository] updateNote called for ID: ${note.id}');
    final updatedNote = note.copyWith(updatedAt: DateTime.now());

    // Update locally first
    final localNotes = await _loadLocalNotes(updatedNote.userId);
    final idx = localNotes.indexWhere((n) => n.id == updatedNote.id);
    if (idx != -1) {
      localNotes[idx] = updatedNote;
      await _saveLocalNotes(updatedNote.userId, localNotes);
    }

    // Try to update in Supabase
    try {
      await _supabase
          .from('notes')
          .update({
            'title': updatedNote.title,
            'course_name': updatedNote.courseName,
            'content': updatedNote.content,
            'updated_at': updatedNote.updatedAt.toIso8601String(),
          })
          .eq('id', updatedNote.id);
      debugPrint('[NotesRepository] updateNote saved to Supabase');
      return updatedNote;
    } catch (e) {
      debugPrint('[NotesRepository] Supabase updateNote failed ($e). Note updated locally.');
      return updatedNote;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String userId, String id) async {
    debugPrint('[NotesRepository] deleteNote called for ID: $id');

    // Delete locally first
    final localNotes = await _loadLocalNotes(userId);
    localNotes.removeWhere((n) => n.id == id);
    await _saveLocalNotes(userId, localNotes);

    // Try to delete from Supabase
    try {
      await _supabase.from('notes').delete().eq('id', id);
      debugPrint('[NotesRepository] deleteNote from Supabase succeeded');
    } catch (e) {
      debugPrint('[NotesRepository] Supabase deleteNote failed ($e). Note deleted locally.');
    }
  }

  // --- Local Cache Helpers ---

  Future<List<Note>> _loadLocalNotes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localKey(userId));
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[NotesRepository] _loadLocalNotes error: $e');
    }

    // Return default initial mock notes if no local cache exists
    return _getDefaultMockNotes(userId);
  }

  Future<void> _saveLocalNotes(String userId, List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(notes.map((n) => n.toLocalJson()).toList());
      await prefs.setString(_localKey(userId), jsonString);
    } catch (e) {
      debugPrint('[NotesRepository] _saveLocalNotes error: $e');
    }
  }

  List<Note> _getDefaultMockNotes(String userId) {
    return [
      Note(
        id: 'mock-1',
        userId: userId,
        courseName: 'Artificial Intelligence',
        title: 'Rangkuman Ujian Tengah Semester',
        content: 'Catatan tentang konsep dasar AI:\n\n1. Search Algorithms: BFS, DFS, A*\n2. Machine Learning: Supervised vs Unsupervised Learning\n3. Neural Networks: Perceptron, Activation Functions.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Note(
        id: 'mock-2',
        userId: userId,
        courseName: 'Database System',
        title: 'Query Optimization Notes',
        content: 'Langkah optimalisasi query SQL:\n\n- Gunakan index pada kolom yang sering di-filter (WHERE).\n- Hindari SELECT * jika hanya butuh beberapa kolom.\n- Gunakan EXPLAIN ANALYZE untuk profil query.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
