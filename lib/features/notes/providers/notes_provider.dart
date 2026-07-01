import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/notes_repository.dart';
import '../../../shared/models/note.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotesRepository(client);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NotesRepository _repository;
  final String? _userId;

  NotesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await loadNotes();
  }

  Future<void> loadNotes() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    debugPrint('[NotesNotifier] loadNotes starting');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getNotes(_userId);
    });
  }

  Future<void> createNote({
    required String title,
    required String courseName,
    required String content,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated.');

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final note = Note(
        id: '',
        userId: userId,
        courseName: courseName,
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.createNote(note);
      return await _repository.getNotes(userId);
    });
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String courseName,
    required String content,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated.');

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final note = Note(
        id: id,
        userId: userId,
        courseName: courseName,
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.updateNote(note);
      return await _repository.getNotes(userId);
    });
  }

  Future<void> deleteNote(String id) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated.');

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteNote(userId, id);
      return await _repository.getNotes(userId);
    });
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return NotesNotifier(repository, userId);
});
