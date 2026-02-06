import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validate email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate password (must contain letters and numbers)
  bool isValidPassword(String password) {
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasDigit && password.length >= 6;
  }

  // Validate PIN (must contain letters and numbers)
  bool isValidPin(String pin) {
    final hasLetter = pin.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = pin.contains(RegExp(r'[0-9]'));
    return hasLetter && hasDigit && pin.length >= 4;
  }

  // Sign up new user
  Future<bool> signUp(String email, String password, String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashedPassword = _hashPassword(password);
      final hashedPin = _hashPassword(pin);

      await prefs.setString('user_email', email);
      await prefs.setString('user_password', hashedPassword);
      await prefs.setString('user_pin', hashedPin);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Sign in existing user
  Future<bool> signIn(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPassword = prefs.getString('user_password');
      final storedEmail = prefs.getString('user_email');
      final hashedPassword = _hashPassword(password);

      return storedPassword == hashedPassword && storedEmail == email;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('user_pin');
      final hashedPin = _hashPassword(pin);

      return storedPin == hashedPin;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_password');
    } catch (e) {
      return false;
    }
  }

  // Get current email
  Future<String?> getCurrentEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (e) {
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Handle error
    }
  }
}