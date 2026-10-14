import 'package:intl/intl.dart';
import 'models.dart';

/// Currency symbols used for the currencies supported by BudgetBuddy.
const Map<String, String> currencySymbols = {
  'PHP': '\u20b1',
  'USD': '\$',
  'EUR': '\u20ac',
  'JPY': '\u00a5',
  'GBP': '\u00a3',
  'SGD': '\$',
};

/// Formats [n] as a currency string for [currency].
///
/// Negative amounts are shown with a leading minus sign so that an
/// overspent balance is displayed correctly (e.g. `-₱10.00`).
String money(double n, String currency) {
  final symbol = currencySymbols[currency] ?? currency;
  final formatted = NumberFormat('#,##0.00').format(n.abs());
  return n < 0 ? '-$symbol$formatted' : '$symbol$formatted';
}

/// Human-readable date, e.g. `Oct 14, 2026`.
String dateText(DateTime d) => DateFormat('MMM d, yyyy').format(d);

/// Generates a unique record identifier combining a timestamp with an
/// in-process counter, so two records created within the same microsecond
/// cannot collide (which would otherwise cause one record to overwrite another).
int _idSequence = 0;
String uniqueId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${_idSequence++}';

/// Sums the amounts of a list of allowance records.
double totalAllowance(List<Allowance> items) =>
    items.fold<double>(0, (s, x) => s + x.amount);

/// Sums the amounts of a list of expense records.
double totalExpenses(List<Expense> items) =>
    items.fold<double>(0, (s, x) => s + x.amount);

/// Remaining balance = allowance - expenses. May be negative.
double remainingBalance(double allowance, double spent) => allowance - spent;

/// Percentage of the allowance that has been spent.
///
/// Returns `0` when the allowance is zero or negative (avoiding a
/// divide-by-zero). Values above 100 are preserved so an overspent budget
/// is reported honestly rather than clamped to zero.
double budgetUsedPercentage(double allowance, double spent) {
  if (allowance <= 0) return 0;
  final p = spent / allowance * 100;
  return p < 0 ? 0 : p;
}

/// Aggregates expense amounts by category for the analytics chart.
Map<String, double> categoryTotals(List<Expense> expenses) {
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
}
