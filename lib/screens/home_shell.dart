import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'analytics_screen.dart';
import 'rates_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.storage, required this.userId});
  final StorageService storage;
  final String userId;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  void _refresh() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final user = widget.storage.userById(widget.userId)!;
    final pages = [
      DashboardScreen(
          storage: widget.storage,
          userId: widget.userId,
          onNavigate: (i) => setState(() => _index = i)),
      RecordsScreen(
          storage: widget.storage,
          userId: widget.userId,
          isExpense: false,
          currency: user.currency,
          onChanged: _refresh),
      RecordsScreen(
          storage: widget.storage,
          userId: widget.userId,
          isExpense: true,
          currency: user.currency,
          onChanged: _refresh),
      AnalyticsScreen(
          storage: widget.storage,
          userId: widget.userId,
          currency: user.currency),
      const RatesScreen(),
      SettingsScreen(
          storage: widget.storage,
          userId: widget.userId,
          onLogout: () async {
            await widget.storage.setSession(null);
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => AuthScreen(storage: widget.storage)),
                (_) => false);
          },
          onChanged: _refresh)
    ];
    const nav = [
      ('Home', Icons.home_outlined, Icons.home),
      ('Allowance', Icons.savings_outlined, Icons.savings),
      ('Expenses', Icons.receipt_long_outlined, Icons.receipt_long),
      ('Analytics', Icons.pie_chart_outline, Icons.pie_chart),
      ('Rates', Icons.currency_exchange_outlined, Icons.currency_exchange),
      ('Settings', Icons.settings_outlined, Icons.settings)
    ];
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
        appBar: AppBar(
            title: const Text('BudgetBuddy'),
            leading: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: AppTheme.purple))),
        body: Row(children: [
          if (wide)
            NavigationRail(
                selectedIndex: _index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: nav
                    .map((n) => NavigationRailDestination(
                        icon: Icon(n.$2),
                        selectedIcon: Icon(n.$3),
                        label: Text(n.$1)))
                    .toList()),
          Expanded(child: IndexedStack(index: _index, children: pages))
        ]),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: nav
                    .map((n) => NavigationDestination(
                        icon: Icon(n.$2),
                        selectedIcon: Icon(n.$3),
                        label: n.$1))
                    .toList()));
  }
}
