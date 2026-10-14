import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_buddy/models.dart';
import 'package:budget_buddy/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty with no session', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    expect(storage.users(), isEmpty);
    expect(storage.allowances('anyone'), isEmpty);
    expect(storage.expenses('anyone'), isEmpty);
    expect(await storage.sessionUserId(), isNull);
  });

  test('saveUser stores and retrieves a user', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    final u = AppUser(
        id: 'u1',
        name: 'Alice',
        email: 'alice@student.edu',
        digest: 'abc',
        currency: 'PHP');
    await storage.saveUser(u);
    expect(storage.users().length, 1);
    expect(storage.userById('u1')!.name, 'Alice');
  });

  test('saveUser updates an existing user in place (no duplicate)', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    final u = AppUser(id: 'u1', name: 'Alice', email: 'a@b.com', digest: 'abc');
    await storage.saveUser(u);
    await storage.saveUser(u.copyWith(name: 'Alice 2', currency: 'USD'));
    expect(storage.users().length, 1);
    final updated = storage.userById('u1')!;
    expect(updated.name, 'Alice 2');
    expect(updated.currency, 'USD');
    expect(updated.email, 'a@b.com');
  });

  test('session is set, restored and cleared', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    final u = AppUser(id: 'u1', name: 'Alice', email: 'a@b.com', digest: 'abc');
    await storage.saveUser(u);
    expect(await storage.sessionUserId(), isNull);
    await storage.setSession('u1');
    expect(await storage.sessionUserId(), 'u1');
    await storage.setSession(null);
    expect(await storage.sessionUserId(), isNull);
  });

  test('stale session to a missing user is not restored', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    await storage.setSession('does-not-exist');
    // userById returns null, so sessionUserId must also return null
    expect(await storage.sessionUserId(), isNull);
  });

  test('allowance edit updates by id without creating duplicates', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    final a = Allowance(
        id: '1',
        userId: 'u1',
        amount: 100,
        date: DateTime(2024, 1, 1),
        description: 'Jan');
    await storage.saveAllowance(a);
    await storage.saveAllowance(Allowance(
        id: '1',
        userId: 'u1',
        amount: 500,
        date: a.date,
        description: a.description));
    expect(storage.allowances('u1').length, 1);
    expect(storage.allowances('u1').first.amount, 500);
  });

  test('deleteAllowance removes only the matched id', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    await storage.saveAllowance(makeAllowance('1', 100));
    await storage.saveAllowance(makeAllowance('2', 200));
    await storage.saveAllowance(makeAllowance('3', 300));
    await storage.deleteAllowance('2');
    final ids = storage.allowances('u1').map((e) => e.id).toSet();
    expect(ids, {'1', '3'});
    expect(storage.allowances('u1').length, 2);
  });

  test('expense edit and delete behave correctly', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    await storage.saveExpense(makeExpense('e1', 100, 'Food'));
    await storage.saveExpense(makeExpense('e2', 200, 'Others'));
    // edit e1
    await storage.saveExpense(makeExpense('e1', 150, 'Food'));
    expect(storage.expenses('u1').length, 2);
    expect(storage.expenses('u1').firstWhere((e) => e.id == 'e1').amount, 150);
    // delete e2
    await storage.deleteExpense('e2');
    expect(storage.expenses('u1').length, 1);
  });

  test('data is isolated per user id', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    await storage.saveAllowance(makeAllowance('1', 100, userId: 'alice'));
    await storage.saveAllowance(makeAllowance('2', 500, userId: 'bob'));
    await storage.saveExpense(makeExpense('e1', 30, 'Food', userId: 'alice'));
    await storage.saveExpense(makeExpense('e2', 60, 'Others', userId: 'bob'));
    expect(storage.allowances('alice').map((a) => a.amount), [100]);
    expect(storage.allowances('bob').map((a) => a.amount), [500]);
    expect(storage.expenses('alice').map((e) => e.amount), [30]);
    expect(storage.expenses('bob').map((e) => e.amount), [60]);
  });

  test('valid records survive a simulated restart', () async {
    final storage = StorageService(await SharedPreferences.getInstance());
    final prefs = await SharedPreferences.getInstance();
    final u = AppUser(id: 'u1', name: 'Alice', email: 'a@b.com', digest: 'd');
    await storage.saveUser(u);
    await storage.saveAllowance(Allowance(
        id: '1',
        userId: 'u1',
        amount: 1000,
        date: DateTime(2024),
        description: 'Jan'));
    await storage.saveExpense(Expense(
        id: '2',
        userId: 'u1',
        amount: 300,
        date: DateTime(2024),
        description: 'Snacks',
        category: 'Food'));
    // Capture the raw persisted strings (simulating on-disk state).
    final rawUsers = prefs.getString(StorageService.usersKey);
    final rawAllow = prefs.getString(StorageService.allowancesKey);
    final rawExp = prefs.getString(StorageService.expensesKey);
    // Simulate a fresh process: re-seed the mock store with the persisted bytes.
    final seed = <String, Object>{};
    if (rawUsers != null) seed[StorageService.usersKey] = rawUsers;
    if (rawAllow != null) seed[StorageService.allowancesKey] = rawAllow;
    if (rawExp != null) seed[StorageService.expensesKey] = rawExp;
    SharedPreferences.setMockInitialValues(seed);
    final storage2 = StorageService(await SharedPreferences.getInstance());
    expect(storage2.users().length, 1);
    expect(storage2.userById('u1')!.name, 'Alice');
    expect(storage2.allowances('u1').length, 1);
    expect(storage2.expenses('u1').length, 1);
    expect(storage2.allowances('u1').first.amount, 1000);
    expect(storage2.expenses('u1').first.category, 'Food');
  });

  test('corrupted JSON does not crash and recovers to empty', () async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(StorageService.usersKey, 'not valid json at all');
    final storage = StorageService(prefs);
    expect(storage.users(), isEmpty);
    expect(storage.userById('u1'), isNull);
  });

  test('partially corrupted records are skipped, valid ones kept', () async {
    final prefs = await SharedPreferences.getInstance();
    final u = AppUser(id: 'u1', name: 'Alice', email: 'a@b.com', digest: 'd');
    // A list with one valid map plus two non-map entries.
    prefs.setString(
        StorageService.usersKey, jsonEncode([u.toJson(), 'garbage', 123]));
    final storage = StorageService(prefs);
    expect(storage.users().length, 1);
    expect(storage.userById('u1')!.name, 'Alice');
  });

  test('records with missing fields fall back to safe defaults', () async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        StorageService.expensesKey,
        jsonEncode([
          {'userId': 'u1'}
        ])); // missing id/amount/date/description/category
    final storage = StorageService(prefs);
    final list = storage.expenses('u1');
    expect(list.length, 1);
    expect(list.first.amount, 0);
    expect(list.first.category, 'Others');
    expect(list.first.description, '');
  });
}

/// Helpers to keep the tests concise.
Allowance makeAllowance(String id, double amount, {String userId = 'u1'}) =>
    Allowance(
        id: id,
        userId: userId,
        amount: amount,
        date: DateTime(2024, 1, 1),
        description: 'record $id');

Expense makeExpense(String id, double amount, String category,
        {String userId = 'u1'}) =>
    Expense(
        id: id,
        userId: userId,
        amount: amount,
        date: DateTime(2024, 1, 1),
        description: 'expense $id',
        category: category);
