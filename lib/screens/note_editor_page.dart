import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../utils/theme.dart';
import '../widgets/gradient_background.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note; // null for new note, existing note for editing

  const NoteEditorPage({Key? key, this.note}) : super(key: key);

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NotesService _notesService = NotesService();
  
  bool _isLocked = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // If editing existing note, populate fields
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isLocked = widget.note!.isLocked;
    }

    // Listen for changes
    _titleController.addListener(() => setState(() => _hasChanges = true));
    _contentController.addListener(() => setState(() => _hasChanges = true));
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
          'Discard Changes?',
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
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    print('🟣 NoteEditor: Saving note...');
    print('   Title: "${_titleController.text.trim()}"');
    print('   Content length: ${_contentController.text.trim().length}');
    print('   Is locked: $_isLocked');
    print('   Is new note: ${widget.note == null}');

    setState(() => _isSaving = true);

    try {
      bool success = false;

      if (widget.note == null) {
        // Creating new note
        print('🟣 NoteEditor: Creating new note...');
        final newNote = await _notesService.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isLocked: _isLocked,
        );
        success = newNote != null;
        print('🟣 NoteEditor: Create result - success: $success, note: $newNote');
      } else {
        // Updating existing note
        print('🟣 NoteEditor: Updating existing note...');
        success = await _notesService.updateNote(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isLocked: _isLocked,
        );
        print('🟣 NoteEditor: Update result - success: $success');
      }

      if (!mounted) return;

      if (success) {
        print('🟣 NoteEditor: Save successful, navigating back...');
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note == null ? 'Note created' : 'Note saved'),
            backgroundColor: AppColors.cyanAzure,
          ),
        );
        Navigator.pop(context, true);
      } else {
        print('🟣 NoteEditor: Save failed!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save note - Check console for details'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('💥 NoteEditor: Exception while saving: $e');
      print('💥 Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.note == null ? 'New Note' : 'Edit Note',
            style: const TextStyle(color: AppColors.pinkLavender),
          ),
          backgroundColor: AppColors.darkSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyanAzure),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isLocked ? Icons.lock : Icons.lock_open,
                color: _isLocked ? AppColors.pinkLavender : AppColors.cyanAzure,
              ),
              onPressed: () {
                setState(() {
                  _isLocked = !_isLocked;
                  _hasChanges = true;
                });
              },
            ),
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cyanAzure,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.cyanAzure),
                onPressed: _saveNote,
              ),
          ],
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Title field
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
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: AppColors.darkSurface),
                  const SizedBox(height: 8),
                  // Content field
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}