import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key,
      required this.storage,
      required this.userId,
      required this.onLogout,
      required this.onChanged});
  final StorageService storage;
  final String userId;
  final Future<void> Function() onLogout;
  final VoidCallback onChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _name;
  late String _currency;
  @override
  void initState() {
    super.initState();
    final u = widget.storage.userById(widget.userId)!;
    _name = TextEditingController(text: u.name);
    _currency = u.currency;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }
    final old = widget.storage.userById(widget.userId)!;
    await widget.storage.saveUser(old.copyWith(name: _name.text.trim()));
    if (!mounted) return;
    widget.onChanged();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.storage.userById(widget.userId)!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Settings',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.ink)),
      const SizedBox(height: 5),
      const Text('Manage your profile and preferences.',
          style: TextStyle(color: AppTheme.muted)),
      const SizedBox(height: 18),
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: u.email,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: Icon(Icons.currency_exchange_outlined)),
                items: currencySymbols.keys
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final current = widget.storage.userById(widget.userId)!;
                  await widget.storage.saveUser(current.copyWith(currency: v));
                  _currency = v;
                  if (!mounted) return;
                  widget.onChanged();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Currency saved.')));
                }),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save settings'))
          ])),
      const SizedBox(height: 16),
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About BudgetBuddy',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                SizedBox(height: 8),
                Text('Version 1.0.0'),
                SizedBox(height: 5),
                Text(
                    'Built with Flutter and Dart. Budget records are stored locally on this device.',
                    style: TextStyle(color: AppTheme.muted))
              ])),
      const SizedBox(height: 16),
      OutlinedButton.icon(
          onPressed: () async {
            final yes = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text(
                            'You can log in again with your account.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Log out'))
                        ]));
            if (yes == true) await widget.onLogout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'))
    ]);
  }
}
