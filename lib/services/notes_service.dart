import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note.dart';
import 'api_service.dart';

class NotesService {
  final ApiService _apiService = ApiService();
  
  // Local storage key for offline notes cache
  static const String _notesKey = 'cached_notes';

  /// Get all notes (from API with local cache fallback)
  Future<List<Note>> getAllNotes() async {
    try {
      // Try to fetch from API
      final notes = await _apiService.getAllNotes();
      
      if (notes.isNotEmpty) {
        // Cache notes locally
        await _cacheNotes(notes);
        return notes;
      } else {
        // If API returns empty, try local cache
        return await _getCachedNotes();
      }
    } catch (e) {
      print('Error fetching notes from API: $e');
      // Fallback to cached notes
      return await _getCachedNotes();
    }
  }

  /// Get a single note by ID
  Future<Note?> getNoteById(String id) async {
    try {
      return await _apiService.getNoteById(id);
    } catch (e) {
      print('Error fetching note: $e');
      // Try to find in local cache
      final cachedNotes = await _getCachedNotes();
      try {
        return cachedNotes.firstWhere((note) => note.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Create a new note
  Future<Note?> createNote({
    required String title,
    required String content,
    bool isLocked = false,
  }) async {
    try {
      final result = await _apiService.createNote(
        title: title,
        content: content,
        isLocked: isLocked,
      );

      if (result['success'] && result['note'] != null) {
        // Refresh cache
        await getAllNotes();
        return result['note'];
      }
      
      return null;
    } catch (e) {
      print('Error creating note: $e');
      return null;
    }
  }

  /// Update an existing note
  Future<bool> updateNote({
    required String id,
    required String title,
    required String content,
    bool? isLocked,
  }) async {
    try {
      final result = await _apiService.updateNote(
        id: id,
        title: title,
        content: content,
        isLocked: isLocked,
      );

      if (result['success']) {
        // Refresh cache
        await getAllNotes();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String id) async {
    try {
      final result = await _apiService.deleteNote(id);

      if (result['success']) {
        // Refresh cache
        await getAllNotes();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  /// Toggle note lock status
  Future<bool> toggleNoteLock(String id) async {
    try {
      final result = await _apiService.toggleNoteLock(id);

      if (result['success']) {
        // Refresh cache
        await getAllNotes();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error toggling lock: $e');
      return false;
    }
  }

  // ==================== LOCAL CACHE METHODS ====================

  /// Cache notes locally for offline access
  Future<void> _cacheNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((note) => note.toMap()).toList();
      await prefs.setString(_notesKey, jsonEncode(notesJson));
    } catch (e) {
      print('Error caching notes: $e');
    }
  }

  /// Get cached notes from local storage
  Future<List<Note>> _getCachedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesString = prefs.getString(_notesKey);
      
      if (notesString != null) {
        final List<dynamic> notesJson = jsonDecode(notesString);
        return notesJson.map((json) => Note.fromMap(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error loading cached notes: $e');
      return [];
    }
  }

  /// Clear local cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
