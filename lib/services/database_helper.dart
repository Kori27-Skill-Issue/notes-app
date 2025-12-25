import '../models/note.dart';

class DatabaseHelper {
  List<Note> _notes = [];
  
  Future<int> addNote(Note note) async {
    _notes.add(note);
    return 1;
  }
  
  Future<List<Note>> getAllNotes() async {
    return _notes;
  }
  
  Future<int> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteNote(int id) async {
    _notes.removeWhere((note) => note.id == id);
    return 1;
  }
  
  Future<List<Note>> searchNotes(String query) async {
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
             note.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}