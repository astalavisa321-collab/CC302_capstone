import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(
      {super.key,
      required this.storage,
      required this.userId,
      required this.onNavigate});
  final StorageService storage;
  final String userId;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final u = storage.userById(userId)!;
    final allowance = totalAllowance(storage.allowances(userId));
    final expenses = storage.expenses(userId)
      ..sort((x, y) => y.date.compareTo(x.date));
    final spent = totalExpenses(expenses);
    final balance = remainingBalance(allowance, spent);
    final pct = budgetUsedPercentage(allowance, spent);
    final width = MediaQuery.sizeOf(context).width;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Welcome, ${u.name} 👋',
          style: const TextStyle(color: AppTheme.muted)),
      const SizedBox(height: 5),
      const Text('Your money at a glance',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.ink)),
      const SizedBox(height: 18),
      Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.purple, Color(0xFF8C7CF2)]),
              borderRadius: BorderRadius.circular(22)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Remaining balance',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(money(balance, u.currency),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
                allowance > 0
                    ? '${pct.toStringAsFixed(0)}% of recorded allowance spent'
                    : 'Add an allowance to begin tracking',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value:
                        allowance > 0 ? (pct / 100).clamp(0, 1).toDouble() : 0,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white)))
          ])),
      const SizedBox(height: 15),
      GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: width >= 650 ? 3 : 2,
          childAspectRatio: width >= 650 ? 1.6 : 1.18,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            SummaryCard(
                title: 'Total allowance',
                value: money(allowance, u.currency),
                icon: Icons.savings_outlined,
                color: AppTheme.green),
            SummaryCard(
                title: 'Total expenses',
                value: money(spent, u.currency),
                icon: Icons.shopping_bag_outlined,
                color: AppTheme.orange),
            SummaryCard(
                title: 'Transactions',
                value: '${expenses.length}',
                icon: Icons.receipt_long_outlined,
                color: AppTheme.purple)
          ]),
      const SizedBox(height: 22),
      const Text('Quick actions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: FilledButton.tonalIcon(
                onPressed: () => onNavigate(1),
                icon: const Icon(Icons.add_card),
                label: const Text('Add allowance'))),
        const SizedBox(width: 10),
        Expanded(
            child: FilledButton.icon(
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add expense')))
      ]),
      const SizedBox(height: 22),
      const Text('Recent expenses',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      const SizedBox(height: 8),
      if (expenses.isEmpty)
        const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            message: 'Add your first expense to see where your money goes.')
      else
        ...expenses.take(5).map((x) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
                backgroundColor: AppTheme.purple.withValues(alpha: .12),
                child: const Icon(Icons.receipt_long, color: AppTheme.purple)),
            title: Text(x.description,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${x.category} • ${dateText(x.date)}'),
            trailing: Text('-${money(x.amount, u.currency)}',
                style: const TextStyle(
                    color: AppTheme.orange, fontWeight: FontWeight.w800))))
    ]);
  }
}
