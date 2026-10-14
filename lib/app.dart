import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/storage_service.dart';
import 'theme.dart';

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key, required this.storage});
  final StorageService storage;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BudgetBuddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FutureBuilder<String?>(
          future: storage.sessionUserId(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final id = snap.data;
            if (id == null || storage.userById(id) == null) {
              return AuthScreen(storage: storage);
            }
            return HomeShell(storage: storage, userId: id);
          },
        ),
      );
}
