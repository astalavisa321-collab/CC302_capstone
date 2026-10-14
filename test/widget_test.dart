import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_buddy/models.dart';
import 'package:budget_buddy/services/storage_service.dart';
import 'package:budget_buddy/utils.dart';
import 'package:budget_buddy/screens/auth_screen.dart';
import 'package:budget_buddy/screens/dashboard_screen.dart';
import 'package:budget_buddy/screens/records_screen.dart';
import 'package:budget_buddy/screens/analytics_screen.dart';

/// Creates an in-memory [StorageService] backed by mock SharedPreferences.
Future<StorageService> makeStorage() async {
  SharedPreferences.setMockInitialValues({});
  return StorageService(await SharedPreferences.getInstance());
}

/// Creates storage pre-seeded with a single user (id `u1`).
Future<StorageService> storageWithUser(String name, String email) async {
  final storage = await makeStorage();
  await storage
      .saveUser(AppUser(id: 'u1', name: name, email: email, digest: 'd'));
  return storage;
}

/// Pumps a [child] inside the same ambient widgets it would have in the app
/// (MaterialApp + Scaffold), so Material-only widgets like ListTile render.
Future<void> pumpScreen(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  test('expense categories and currency formatting', () {
    expect(categories.length, 7);
    expect(money(125.5, 'PHP'), contains('125.50'));
  });

  group('AuthScreen', () {
    testWidgets('renders the title and toggles to registration',
        (tester) async {
      final storage = await makeStorage();
      await tester.pumpWidget(MaterialApp(home: AuthScreen(storage: storage)));
      expect(find.text('BudgetBuddy'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      // name field is absent in login mode
      expect(find.text('Display name'), findsNothing);

      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
      expect(tester.widgetList(find.byType(TextFormField)).length, 4);
    });
  });

  group('DashboardScreen', () {
    testWidgets('shows welcome, zero totals and an empty-state hint',
        (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await pumpScreen(tester,
          DashboardScreen(storage: storage, userId: 'u1', onNavigate: (i) {}));
      expect(find.text('Welcome, Alice \ud83d\udc4b'), findsOneWidget);
      expect(find.text('Add an allowance to begin tracking'), findsOneWidget);
      // allowance / expenses / balance all render as 0.00
      expect(find.text('\u20b10.00'), findsNWidgets(3));
    });

    testWidgets('totals reflect allowance and expenses', (tester) async {
      final storage = await storageWithUser('Bob', 'b@c.com');
      await storage.saveAllowance(Allowance(
          id: '1',
          userId: 'u1',
          amount: 1000,
          date: DateTime(2024, 1, 1),
          description: 'January'));
      await storage.saveExpense(Expense(
          id: 'e1',
          userId: 'u1',
          amount: 300,
          date: DateTime(2024, 1, 5),
          description: 'Snacks',
          category: 'Food'));
      await pumpScreen(tester,
          DashboardScreen(storage: storage, userId: 'u1', onNavigate: (i) {}));
      expect(find.text('\u20b11,000.00'), findsOneWidget); // allowance
      expect(find.text('\u20b1300.00'), findsOneWidget); // expenses
      expect(find.text('30% of recorded allowance spent'), findsOneWidget);
    });

    testWidgets('shows a negative balance when overspent', (tester) async {
      final storage = await storageWithUser('Cara', 'c@d.com');
      await storage.saveAllowance(Allowance(
          id: '1',
          userId: 'u1',
          amount: 100,
          date: DateTime(2024, 1, 1),
          description: 'Jan'));
      await storage.saveExpense(Expense(
          id: 'e1',
          userId: 'u1',
          amount: 250,
          date: DateTime(2024, 1, 5),
          description: 'Party',
          category: 'Entertainment'));
      await pumpScreen(tester,
          DashboardScreen(storage: storage, userId: 'u1', onNavigate: (i) {}));
      expect(find.text('-\u20b1150.00'), findsOneWidget);
    });
  });

  group('RecordsScreen', () {
    testWidgets('shows an empty state for a fresh user', (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await pumpScreen(
          tester,
          RecordsScreen(
              storage: storage,
              userId: 'u1',
              isExpense: true,
              currency: 'PHP',
              onChanged: () {}));
      expect(find.text('No records yet'), findsOneWidget);
    });

    testWidgets('filters expenses by search text', (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await storage.saveExpense(Expense(
          id: '1',
          userId: 'u1',
          amount: 100,
          date: DateTime(2024, 1, 1),
          description: 'Apple juice',
          category: 'Food'));
      await storage.saveExpense(Expense(
          id: '2',
          userId: 'u1',
          amount: 50,
          date: DateTime(2024, 1, 2),
          description: 'Textbook',
          category: 'School Supplies'));
      await pumpScreen(
          tester,
          RecordsScreen(
              storage: storage,
              userId: 'u1',
              isExpense: true,
              currency: 'PHP',
              onChanged: () {}));
      expect(find.text('Apple juice'), findsOneWidget);
      expect(find.text('Textbook'), findsOneWidget);

      final searchField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.hintText == 'Search records...');
      await tester.enterText(searchField, 'text');
      await tester.pumpAndSettle();

      expect(find.text('Textbook'), findsOneWidget);
      expect(find.text('Apple juice'), findsNothing);
    });

    testWidgets('adds a new expense and shows it', (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await pumpScreen(
          tester,
          RecordsScreen(
              storage: storage,
              userId: 'u1',
              isExpense: true,
              currency: 'PHP',
              onChanged: () {}));

      await tester.tap(find.text('Add expense'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'), '49.5');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'What did you buy?'), 'Coffee');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(storage.expenses('u1').length, 1);
      expect(storage.expenses('u1').first.amount, 49.5);
    });
  });

  group('AnalyticsScreen', () {
    testWidgets('shows an empty state with no expenses', (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await pumpScreen(tester,
          AnalyticsScreen(storage: storage, userId: 'u1', currency: 'PHP'));
      expect(find.text('Nothing to chart yet'), findsOneWidget);
      expect(find.text('\u20b10.00'), findsNothing);
    });

    testWidgets('renders totals after expenses are added', (tester) async {
      final storage = await storageWithUser('Alice', 'a@b.com');
      await pumpScreen(tester,
          AnalyticsScreen(storage: storage, userId: 'u1', currency: 'PHP'));
      expect(find.text('Nothing to chart yet'), findsOneWidget);

      await storage.saveExpense(Expense(
          id: '1',
          userId: 'u1',
          amount: 100,
          date: DateTime(2024),
          description: 'Food',
          category: 'Food'));
      await storage.saveExpense(Expense(
          id: '2',
          userId: 'u1',
          amount: 100,
          date: DateTime(2024),
          description: 'Books',
          category: 'Others'));

      await pumpScreen(tester,
          AnalyticsScreen(storage: storage, userId: 'u1', currency: 'PHP'));
      expect(find.text('Nothing to chart yet'), findsNothing);
      expect(find.text('\u20b1200.00'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });
  });
}
