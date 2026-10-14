import 'dart:convert';
import '../models.dart';
import '../utils.dart';
import 'storage_service.dart';

/// Local classroom-demo authentication.
///
/// Passwords are stored as a lightweight FNV-1a digest. This is **not**
/// production-grade password hashing (no salt, fast hash, stored locally)
/// and is suitable only for a classroom demo. Do not use a real password.
class AuthService {
  AuthService(this.storage);

  final StorageService storage;

  /// FNV-1a (32-bit) digest used for the local demo only.
  String _digest(String s) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  String _id() => uniqueId();

  String? validateName(String name) {
    if (name.trim().isEmpty) return 'Enter your name.';
    return null;
  }

  String? validateEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return 'Enter your email.';
    if (!e.contains('@') || !e.contains('.')) return 'Enter a valid email.';
    return null;
  }

  String? validatePassword(String password) {
    if (password.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  String? validateConfirmPassword(String password, String confirmPassword) {
    if (password != confirmPassword) return 'Passwords do not match.';
    return null;
  }

  /// Validates a registration form; returns the first error or `null`.
  String? validateRegistration(String name, String email, String password, String confirmPassword) =>
      validateName(name) ?? validateEmail(email) ?? validatePassword(password) ?? validateConfirmPassword(password, confirmPassword);

  /// Registers a new user. Returns an error message, or `null` on success.
  Future<String?> register(String name, String email, String password, String confirmPassword) async {
    final err = validateRegistration(name, email, password, confirmPassword);
    if (err != null) return err;
    final em = email.trim().toLowerCase();
    if (storage.users().any((u) => u.email == em)) {
      return 'An account with this email already exists.';
    }
    final u = AppUser(
        id: _id(), name: name.trim(), email: em, digest: _digest(password));
    await storage.saveUser(u);
    await storage.setSession(u.id);
    return null;
  }

  /// Logs in an existing user. Returns an error message, or `null` on success.
  Future<String?> login(String email, String password) async {
    final err = validateEmail(email);
    if (err != null) return err;
    if (password.isEmpty) return 'Enter your password.';
    final em = email.trim().toLowerCase();
    for (final u in storage.users()) {
      if (u.email == em && u.digest == _digest(password)) {
        await storage.setSession(u.id);
        return null;
      }
    }
    return 'Incorrect email or password.';
  }
}
