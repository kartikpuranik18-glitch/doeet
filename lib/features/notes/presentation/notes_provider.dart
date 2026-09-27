// lib/features/notes/presentation/notes_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/note_model.dart';
import '../data/notes_repository.dart';
import '../../auth/presentation/auth_provider.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) => NotesRepository());

/// Stream notes for a specific course
final notesProvider =
    StreamProvider.family<List<NoteModel>, String>((ref, courseId) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(notesRepositoryProvider).watchNotes(uid, courseId);
});

/// Stream ALL notes for the current user (used in NotesScreen)
final allNotesProvider = StreamProvider<List<NoteModel>>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(notesRepositoryProvider).watchAllNotes(uid);
});

class NotesNotifier extends StateNotifier<AsyncValue<void>> {
  NotesNotifier(this._repo, this._uid) : super(const AsyncValue.data(null));

  final NotesRepository _repo;
  final String _uid;

  /// Save or update a note — accepts either a NoteModel or named fields
  Future<String?> saveNote({
    String? id,
    required String courseId,
    String? videoId,
    required String title,
    required String content,
    int? timestamp,
  }) async {
    state = const AsyncValue.loading();
    String? savedId;
    state = await AsyncValue.guard(() async {
      final note = NoteModel(
        id: id ?? '',
        courseId: courseId,
        videoId: videoId,
        title: title,
        content: content,
        timestamp: timestamp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      savedId = await _repo.saveNote(_uid, note);
    });
    return savedId;
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteNote(_uid, noteId));
  }
}

final notesNotifierProvider =
    StateNotifierProvider.autoDispose<NotesNotifier, AsyncValue<void>>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  return NotesNotifier(ref.watch(notesRepositoryProvider), uid);
});
