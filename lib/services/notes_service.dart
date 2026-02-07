import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note.dart';

class NotesService {
  static const String _notesKey = 'notes_list';

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson == null) return [];
      
      final List<dynamic> notesList = json.decode(notesJson);
      return notesList.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save notes to storage
  Future<bool> _saveNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(notes.map((note) => note.toJson()).toList());
      await prefs.setString(_notesKey, notesJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Add new note
  Future<bool> addNote(Note note) async {
    try {
      final notes = await getAllNotes();
      notes.insert(0, note); // Add to beginning
      return await _saveNotes(notes);
    } catch (e) {
      return false;
    }
  }

  // Update existing note
  Future<bool> updateNote(Note updatedNote) async {
    try {
      final notes = await getAllNotes();
      final index = notes.indexWhere((note) => note.id == updatedNote.id);
      
      if (index != -1) {
        notes[index] = updatedNote;
        return await _saveNotes(notes);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      final notes = await getAllNotes();
      notes.removeWhere((note) => note.id == noteId);
      return await _saveNotes(notes);
    } catch (e) {
      return false;
    }
  }

  // Toggle note lock status
  Future<bool> toggleNoteLock(String noteId) async {
    try {
      final notes = await getAllNotes();
      final index = notes.indexWhere((note) => note.id == noteId);
      
      if (index != -1) {
        notes[index] = notes[index].copyWith(
          isLocked: !notes[index].isLocked,
          updatedAt: DateTime.now(),
        );
        return await _saveNotes(notes);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Search notes
  Future<List<Note>> searchNotes(String query) async {
    try {
      final notes = await getAllNotes();
      final lowerQuery = query.toLowerCase();
      
      return notes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
               note.content.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get note by ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      final notes = await getAllNotes();
      return notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }
}