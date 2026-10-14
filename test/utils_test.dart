import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/models.dart';
import 'package:budget_buddy/utils.dart';

void main() {
  group('money formatting', () {
    test('formats PHP with the peso sign', () {
      expect(money(125.5, 'PHP'), '\u20b1125.50');
    });
    test('places the minus sign before the symbol for negatives', () {
      expect(money(-100.0, 'PHP'), '-\u20b1100.00');
    });
    test('formats the supported currency symbols', () {
      expect(money(10, 'EUR'), '\u20ac10.00');
      expect(money(10, 'USD'), r'$10.00');
      expect(money(10, 'JPY'), '\u00a510.00');
      expect(money(10, 'GBP'), '\u00a310.00');
      expect(money(10, 'SGD'), r'$10.00');
    });
    test('falls back to the currency code for unknown currencies', () {
      expect(money(10, 'XYZ'), 'XYZ10.00');
    });
  });

  group('budget calculations', () {
    final allowances = [
      Allowance(
          id: '1',
          userId: 'u1',
          amount: 1000,
          date: DateTime(2024, 1, 1),
          description: 'January'),
      Allowance(
          id: '2',
          userId: 'u1',
          amount: 500,
          date: DateTime(2024, 2, 1),
          description: 'February'),
    ];
    final expenses = [
      Expense(
          id: 'a',
          userId: 'u1',
          amount: 250,
          date: DateTime(2024, 1, 5),
          description: 'Snacks',
          category: 'Food'),
      Expense(
          id: 'b',
          userId: 'u1',
          amount: 750,
          date: DateTime(2024, 1, 6),
          description: 'Textbooks',
          category: 'School Supplies'),
    ];

    test('total allowance sums all records', () {
      expect(totalAllowance(allowances), 1500);
    });
    test('total expenses sums all records', () {
      expect(totalExpenses(expenses), 1000);
    });
    test('remaining balance is allowance minus expenses', () {
      expect(remainingBalance(1500, 1000), 500);
    });
    test('remaining balance is negative when overspent', () {
      expect(remainingBalance(1500, 2000), -500);
    });
    test('zero allowance yields 0 percent (no divide-by-zero)', () {
      expect(budgetUsedPercentage(0, 100), 0);
    });
    test('negative allowance yields 0 percent', () {
      expect(budgetUsedPercentage(-50, 100), 0);
    });
    test('percentage exceeds 100 when overspent', () {
      expect(budgetUsedPercentage(1000, 1500), 150);
    });
    test('percentage is never negative', () {
      expect(budgetUsedPercentage(1000, -50), 0);
    });
  });

  group('category aggregation', () {
    test('aggregates expenses by category with correct percentages', () {
      final expenses = [
        Expense(
            id: '1',
            userId: 'u',
            amount: 100,
            date: DateTime(2024),
            description: 'Snacks',
            category: 'Food'),
        Expense(
            id: '2',
            userId: 'u',
            amount: 50,
            date: DateTime(2024),
            description: 'Fruit',
            category: 'Food'),
        Expense(
            id: '3',
            userId: 'u',
            amount: 200,
            date: DateTime(2024),
            description: 'Stationery',
            category: 'Others'),
      ];
      final totals = categoryTotals(expenses);
      expect(totals['Food'], 150);
      expect(totals['Others'], 200);
      final total = totals.values.fold<double>(0, (s, e) => s + e);
      expect(total, 350);
      expect((totals['Food']! / total * 100).toStringAsFixed(1), '42.9');
      expect((totals['Others']! / total * 100).toStringAsFixed(1), '57.1');
    });
    test('returns an empty map with no expenses', () {
      expect(categoryTotals([]), isEmpty);
    });
  });
}
