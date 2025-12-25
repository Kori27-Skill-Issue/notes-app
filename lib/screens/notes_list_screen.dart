import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/note.dart';
import './note_edit_screen.dart';
import '../widgets/note_card.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<Color> _noteColors = [
    Colors.white,
    Color(0xFFFFCDD2),
    Color(0xFFF8BBD0),
    Color(0xFFE1BEE7),
    Color(0xFFC5CAE9),
    Color(0xFFB3E5FC),
    Color(0xFFB2EBF2),
    Color(0xFFC8E6C9),
    Color(0xFFF0F4C3),
    Color(0xFFFFF9C4),
    Color(0xFFFFECB3),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _databaseHelper.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
    });
  }

  void _filterNotes(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          onSave: (title, content) async {
            final newNote = Note(
              title: title.isEmpty ? 'Без названия' : title,
              content: content,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _databaseHelper.addNote(newNote);
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
          onSave: (title, content) async {
            final updatedNote = note.copyWith(
              title: title.isEmpty ? 'Без названия' : title,
              content: content,
              updatedAt: DateTime.now(),
            );
            await _databaseHelper.updateNote(updatedNote);
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.push_pin),
                title: Text('Закрепить'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinNote(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.color_lens),
                title: Text('Изменить цвет'),
                onTap: () {
                  Navigator.pop(context);
                  _showColorPicker(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(note);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _togglePinNote(Note note) async {
    final updatedNote = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await _databaseHelper.updateNote(updatedNote);
    _loadNotes();
  }

  void _showColorPicker(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Выберите цвет',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _noteColors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _changeNoteColor(note, index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _noteColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: index == 0
                          ? Icon(Icons.clear, color: Colors.grey)
                          : null,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _changeNoteColor(Note note, int colorIndex) async {
    final updatedNote = note.copyWith(
      color: colorIndex,
      updatedAt: DateTime.now(),
    );
    await _databaseHelper.updateNote(updatedNote);
    _loadNotes();
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить заметку'),
        content: Text('Вы уверены, что хотите удалить эту заметку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _databaseHelper.deleteNote(note.id!);
              _loadNotes();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск заметок...',
                  border: InputBorder.none,
                ),
                onChanged: _filterNotes,
              )
            : Text('Заметки'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filterNotes('');
                });
              },
            ),
        ],
      ),
      body: _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Заметок пока нет\nНажмите + чтобы добавить',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return NoteCard(
                  note: note,
                  onTap: () => _editNote(note),
                  onLongPress: () => _showNoteOptions(note),
                  noteColors: _noteColors,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ),
    );
  }
}