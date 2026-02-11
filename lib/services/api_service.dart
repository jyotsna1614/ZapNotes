import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class ApiService {
  // Base URL for ZapNotes API
  static const String baseUrl = 'https://zapnotes-rdw6.onrender.com';
  
  // API Endpoints
  static const String signUpEndpoint = '/auth/register';
  static const String signInEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String notesEndpoint = '/notes';
  
  // Timeout duration (Render.com free tier can take time to wake up)
  static const Duration timeoutDuration = Duration(seconds: 60);
  
  // Get stored auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Save auth token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Remove auth token
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // ==================== AUTH ENDPOINTS ====================
  
  /// Sign up a new user
  /// Returns: {success: bool, message: String, token: String?}
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String secretCode,
    required String vaultKeyType,
  }) async {
    try {
      print('🔵 Attempting signup...');
      print('📧 Email: $email');
      print('🔐 Password length: ${password.length}');
      print('🔑 Secret Code: $secretCode');
      print('🔐 Vault Key Type: $vaultKeyType');
      print('🌐 URL: $baseUrl$signUpEndpoint');
      
      final requestBody = {
        'email': email,
        'password': password,
        'secretCode': secretCode,
        'vaultKeyType': vaultKeyType,
      };
      
      print('📤 Request body: ${jsonEncode(requestBody)}');
      print('⏳ Waiting for response (may take up to 60 seconds if server is waking up)...');
      
      final response = await http.post(
        Uri.parse('$baseUrl$signUpEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        timeoutDuration,
        onTimeout: () {
          print('⏰ Request timed out after ${timeoutDuration.inSeconds} seconds');
          throw TimeoutException('Request timed out - server may be sleeping');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        print('⚠️ Empty response body');
        return {
          'success': response.statusCode == 200 || response.statusCode == 201,
          'message': response.statusCode == 200 || response.statusCode == 201
              ? 'Sign up successful'
              : 'Sign up failed with status ${response.statusCode}',
        };
      }
      
      final data = jsonDecode(response.body);
      print('📊 Parsed data: $data');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save token if provided
        if (data['token'] != null) {
          print('✅ Token received, saving...');
          await _saveToken(data['token']);
        } else {
          print('⚠️ No token in response');
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Sign up successful',
          'token': data['token'],
        };
      } else {
        print('❌ Sign up failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Sign up failed',
        };
      }
    } on TimeoutException catch (e) {
      print('💥 Timeout exception: $e');
      return {
        'success': false,
        'message': 'Request timed out. The server may be waking up. Please try again in a moment.',
      };
    } catch (e) {
      print('💥 Exception in signUp: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  /// Sign in existing user
  /// Returns: {success: bool, message: String, token: String?}
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Attempting signin...');
      print('📧 Email: $email');
      print('🌐 URL: $baseUrl$signInEndpoint');
      print('⏳ Waiting for response...');
      
      final response = await http.post(
        Uri.parse('$baseUrl$signInEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        timeoutDuration,
        onTimeout: () {
          print('⏰ Request timed out after ${timeoutDuration.inSeconds} seconds');
          throw TimeoutException('Request timed out');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        return {
          'success': response.statusCode == 200,
          'message': response.statusCode == 200
              ? 'Sign in successful'
              : 'Sign in failed with status ${response.statusCode}',
        };
      }
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save token
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Sign in successful',
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Invalid credentials',
        };
      }
    } on TimeoutException catch (e) {
      print('💥 Timeout exception: $e');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      print('💥 Exception in signIn: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  /// Logout user
  Future<bool> logout() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$logoutEndpoint'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      // Remove token regardless of response
      await _removeToken();
      
      return response.statusCode == 200;
    } catch (e) {
      // Remove token even on error
      await _removeToken();
      return false;
    }
  }
  
  /// Verify security PIN
  Future<Map<String, dynamic>> verifyPin(String pin) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-pin'),
        headers: headers,
        body: jsonEncode({'pin': pin}),
      ).timeout(timeoutDuration);
      
      final data = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? '',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out: $e',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  // ==================== NOTES ENDPOINTS ====================
  
  /// Get all notes for the current user
  Future<List<Note>> getAllNotes() async {
    try {
      final headers = await _getHeaders();
      
      print('🔵 Fetching all notes...');
      print('🌐 URL: $baseUrl$notesEndpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$notesEndpoint'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        print('📊 Parsed data: $data');
        print('📊 Data type: ${data.runtimeType}');
        
        // Handle both array and object responses
        List<dynamic> notesJson;
        if (data is List) {
          // Backend returns array directly
          notesJson = data;
          print('✅ Response is a List with ${notesJson.length} items');
        } else if (data is Map) {
          // Backend returns object with 'notes' or 'data' field
          notesJson = data['notes'] ?? data['data'] ?? [];
          print('✅ Response is a Map, extracted ${notesJson.length} notes');
        } else {
          print('❌ Unexpected response type: ${data.runtimeType}');
          return [];
        }
        
        print('📝 Notes count: ${notesJson.length}');
        
        final notes = notesJson.map((json) => Note.fromJson(json)).toList();
        print('✅ Parsed ${notes.length} notes successfully');
        
        return notes;
      } else {
        print('❌ Failed to fetch notes: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('💥 Error fetching notes: $e');
      print('💥 Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Get a single note by ID
  Future<Note?> getNoteById(String id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl$notesEndpoint/$id'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Note.fromJson(data['note'] ?? data['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching note: $e');
      return null;
    }
  }
  
  /// Create a new note
  Future<Map<String, dynamic>> createNote({
    required String title,
    required String content,
    bool isLocked = false,
  }) async {
    try {
      final headers = await _getHeaders();
      
      print('🔵 Creating note...');
      print('📝 Title: $title');
      print('📝 Content length: ${content.length}');
      print('🔒 Is locked: $isLocked');
      
      final response = await http.post(
        Uri.parse('$baseUrl$notesEndpoint'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          'isLocked': isLocked,
        }),
      ).timeout(timeoutDuration);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      print('📊 Parsed data: $data');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Note created successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Note created successfully',
          'note': data['note'] != null ? Note.fromJson(data['note']) : null,
        };
      } else {
        print('❌ Failed to create note: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create note',
        };
      }
    } on TimeoutException catch (e) {
      print('💥 Timeout exception: $e');
      return {
        'success': false,
        'message': 'Request timed out: $e',
      };
    } catch (e) {
      print('💥 Exception in createNote: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  /// Update an existing note
  Future<Map<String, dynamic>> updateNote({
    required String id,
    required String title,
    required String content,
    bool? isLocked,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {
        'title': title,
        'content': content,
      };
      
      if (isLocked != null) {
        body['isLocked'] = isLocked;
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl$notesEndpoint/$id'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(timeoutDuration);
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Note updated successfully',
          'note': data['note'] != null ? Note.fromJson(data['note']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update note',
        };
      }
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out: $e',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  /// Delete a note
  Future<Map<String, dynamic>> deleteNote(String id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl$notesEndpoint/$id'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Note deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete note',
        };
      }
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out: $e',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  
  /// Toggle note lock status
  Future<Map<String, dynamic>> toggleNoteLock(String id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$notesEndpoint/$id/lock'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Note lock status updated',
          'note': data['note'] != null ? Note.fromJson(data['note']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to toggle lock',
        };
      }
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out: $e',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}