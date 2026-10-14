class AppUser {
  AppUser(
      {required this.id,
      required this.name,
      required this.email,
      required this.digest,
      this.currency = 'PHP'});
  final String id, name, email, digest;
  final String currency;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'digest': digest,
        'currency': currency
      };

  /// Defensive parser: corrupted or missing fields fall back to safe
  /// defaults instead of throwing, so one bad record cannot crash the app.
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? 'User',
        email: j['email'] as String? ?? '',
        digest: j['digest'] as String? ?? '',
        currency: (j['currency'] as String?) ?? 'PHP',
      );

  AppUser copyWith({String? name, String? currency}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        digest: digest,
        currency: currency ?? this.currency,
      );
}

class Allowance {
  Allowance(
      {required this.id,
      required this.userId,
      required this.amount,
      required this.date,
      required this.description});
  final String id, userId, description;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description
      };

  factory Allowance.fromJson(Map<String, dynamic> j) => Allowance(
        id: j['id'] as String? ?? '',
        userId: j['userId'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        date: _safeDate(j['date']),
        description: j['description'] as String? ?? '',
      );
}

class Expense {
  Expense(
      {required this.id,
      required this.userId,
      required this.amount,
      required this.date,
      required this.description,
      required this.category});
  final String id, userId, description, category;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'category': category
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String? ?? '',
        userId: j['userId'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        date: _safeDate(j['date']),
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? 'Others',
      );
}

/// Parses a stored date string, falling back to `DateTime.now()` when the
/// value is missing or malformed.
DateTime _safeDate(dynamic value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

const List<String> categories = [
  'Food',
  'Transportation',
  'School Supplies',
  'Load & Data',
  'Personal Needs',
  'Entertainment',
  'Others'
];
