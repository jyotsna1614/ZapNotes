import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../widgets/gradient_background.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({Key? key, this.note}) : super(key: key);

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final NotesService _notesService = NotesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    
    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }

    _titleController.addListener(() => _hasChanges = true);
    _contentController.addListener(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Discard changes?',
          style: TextStyle(color: AppColors.cyanAzure),
        ),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.pinkLavender),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success;
    
    if (_isEditing) {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      success = await _notesService.updateNote(updatedNote);
    } else {
      // Create new note
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await _notesService.addNote(newNote);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Note updated' : 'Note created'),
          backgroundColor: AppColors.cyanAzure,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save note'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyanAzure),
            onPressed: () async {
              if (await _onWillPop()) {
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _isEditing ? 'Edit Note' : 'New Note',
            style: const TextStyle(color: AppColors.pinkLavender),
          ),
          backgroundColor: AppColors.darkSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.cyanAzure),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyanAzure,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
