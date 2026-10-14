import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_buddy/models.dart';
import 'package:budget_buddy/services/auth_service.dart';
import 'package:budget_buddy/services/storage_service.dart';

void main() {
  late StorageService storage;
  late AuthService auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
    auth = AuthService(storage);
  });

  group('registration validation', () {
    test('empty name is rejected', () async {
      expect(
          await auth.register('', 'a@b.com', 'secret123', 'secret123'), 'Enter your name.');
    });
    test('invalid email is rejected', () async {
      expect(await auth.register('Alice', 'not-an-email', 'secret123', 'secret123'),
          'Enter a valid email.');
    });
    test('email without a dot is rejected', () async {
      expect(await auth.register('Alice', 'a@b', 'secret123', 'secret123'),
          'Enter a valid email.');
    });
    test('short password is rejected', () async {
      expect(await auth.register('Alice', 'a@b.com', '123', '123'),
          'Use at least 6 characters.');
    });
    test('empty email is rejected', () async {
      expect(
          await auth.register('Alice', '', 'secret123', 'secret123'), 'Enter your email.');
    });
    test('mismatched confirm password is rejected', () async {
      expect(await auth.register('Alice', 'a@b.com', 'secret123', 'different'),
          'Passwords do not match.');
    });
  });

  test('duplicate email is rejected', () async {
    expect(await auth.register('Alice', 'a@b.com', 'secret123', 'secret123'), isNull);
    expect(await auth.register('Bob', 'a@b.com', 'secret123', 'secret123'),
        'An account with this email already exists.');
  });

  test('registration stores the user and a session', () async {
    expect(await auth.register('Alice', 'a@b.com', 'secret123', 'secret123'), isNull);
    expect(storage.users().length, 1);
    expect(storage.users().single.email, 'a@b.com');
    expect(await storage.sessionUserId(), isNotEmpty);
  });

  group('login', () {
    setUp(() async {
      await auth.register('Alice', 'a@b.com', 'secret123', 'secret123');
      // Move the session away so login test starts clean.
      await storage.setSession(null);
    });

    test('succeeds with correct credentials', () async {
      expect(await auth.login('a@b.com', 'secret123'), isNull);
      expect(await storage.sessionUserId(), isNotEmpty);
    });
    test('fails with the wrong password', () async {
      expect(await auth.login('a@b.com', 'wrong-password'),
          'Incorrect email or password.');
      expect(await storage.sessionUserId(), isNull);
    });
    test('fails with an unknown email', () async {
      expect(await auth.login('nobody@else.com', 'secret123'),
          'Incorrect email or password.');
      expect(await storage.sessionUserId(), isNull);
    });
    test('email matching is case-insensitive', () async {
      expect(await auth.login('A@B.com', 'secret123'), isNull);
    });
  });

  test('accounts are isolated by id', () async {
    await auth.register('Alice', 'alice@student.edu', 'secret123', 'secret123');
    final aliceId = await storage.sessionUserId();
    await auth.register('Bob', 'bob@student.edu', 'secret123', 'secret123');
    final bobId = await storage.sessionUserId();
    expect(aliceId, isNotNull);
    expect(bobId, isNotNull);
    expect(aliceId, isNot(bobId));

    await storage.saveAllowance(Allowance(
        id: '1',
        userId: aliceId!,
        amount: 1000,
        date: DateTime(2024),
        description: ' allowance'));
    await storage.saveAllowance(Allowance(
        id: '2',
        userId: bobId!,
        amount: 50,
        date: DateTime(2024),
        description: 'Bob only'));
    expect(storage.allowances(aliceId).map((a) => a.amount), [1000]);
    expect(storage.allowances(bobId).map((a) => a.amount), [50]);
  });
}
