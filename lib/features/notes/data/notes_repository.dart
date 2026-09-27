// lib/features/notes/data/notes_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'note_model.dart';

class NotesRepository {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  NotesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCol(String uid) =>
      _db.collection('users').doc(uid).collection('notes');

  Stream<List<NoteModel>> watchNotes(String uid, String courseId) {
    return _notesCol(uid)
        .where('courseId', isEqualTo: courseId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => NoteModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream ALL notes for the user (no courseId filter)
  Stream<List<NoteModel>> watchAllNotes(String uid) {
    return _notesCol(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => NoteModel.fromMap(d.data(), d.id)).toList());
  }

  Future<String> saveNote(String uid, NoteModel note) async {
    final id = note.id.isEmpty ? _uuid.v4() : note.id;
    await _notesCol(uid).doc(id).set(note.toMap(), SetOptions(merge: true));
    return id;
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _notesCol(uid).doc(noteId).delete();
  }

  Future<NoteModel?> fetchNote(String uid, String noteId) async {
    final doc = await _notesCol(uid).doc(noteId).get();
    if (!doc.exists) return null;
    return NoteModel.fromMap(doc.data()!, doc.id);
  }
}
