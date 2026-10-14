import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StorageService {
  StorageService(this.prefs);
  final SharedPreferences prefs;
  static const usersKey = 'bb_users_v1',
      allowancesKey = 'bb_allowances_v1',
      expensesKey = 'bb_expenses_v1',
      sessionKey = 'bb_session_v1';
  List<Map<String, dynamic>> _read(String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final v = jsonDecode(raw);
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> data) async {
    await prefs.setString(key, jsonEncode(data));
  }

  List<AppUser> users() => _read(usersKey).map(AppUser.fromJson).toList();
  AppUser? userById(String id) {
    for (final u in users()) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<void> saveUser(AppUser u) async {
    final a = _read(usersKey);
    final i = a.indexWhere((e) => e['id'] == u.id);
    if (i < 0) {
      a.add(u.toJson());
    } else {
      a[i] = u.toJson();
    }
    await _write(usersKey, a);
  }

  Future<void> saveAllowance(Allowance a) async {
    final all = _read(allowancesKey);
    final i = all.indexWhere((e) => e['id'] == a.id);
    if (i < 0) {
      all.add(a.toJson());
    } else {
      all[i] = a.toJson();
    }
    await _write(allowancesKey, all);
  }

  List<Allowance> allowances(String userId) => _read(allowancesKey)
      .where((e) => e['userId'] == userId)
      .map(Allowance.fromJson)
      .toList();
  Future<void> deleteAllowance(String id) async {
    final a = _read(allowancesKey)..removeWhere((e) => e['id'] == id);
    await _write(allowancesKey, a);
  }

  Future<void> saveExpense(Expense e) async {
    final all = _read(expensesKey);
    final i = all.indexWhere((x) => x['id'] == e.id);
    if (i < 0) {
      all.add(e.toJson());
    } else {
      all[i] = e.toJson();
    }
    await _write(expensesKey, all);
  }

  List<Expense> expenses(String userId) => _read(expensesKey)
      .where((e) => e['userId'] == userId)
      .map(Expense.fromJson)
      .toList();
  Future<void> deleteExpense(String id) async {
    final a = _read(expensesKey)..removeWhere((e) => e['id'] == id);
    await _write(expensesKey, a);
  }

  Future<void> setSession(String? id) async {
    if (id == null) {
      await prefs.remove(sessionKey);
    } else {
      await prefs.setString(sessionKey, id);
    }
  }

  Future<String?> sessionUserId() async {
    final id = prefs.getString(sessionKey);
    return id != null && userById(id) != null ? id : null;
  }
}
