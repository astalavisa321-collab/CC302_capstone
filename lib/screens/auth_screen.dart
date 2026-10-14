import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'home_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.storage});
  final StorageService storage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  bool _hide = true;
  bool _busy = false;
  late final AuthService _auth = AuthService(widget.storage);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = _register
        ? await _auth.register(_name.text, _email.text, _password.text, _confirmPassword.text)
        : await _auth.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final id = await widget.storage.sessionUserId();
    if (!mounted || id == null) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => HomeShell(storage: widget.storage, userId: id)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          alignment: Alignment.center,
                          child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  color: AppTheme.purple,
                                  borderRadius: BorderRadius.circular(22)),
                              child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 40,
                                  color: Colors.white))),
                      const SizedBox(height: 18),
                      const Text('BudgetBuddy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.ink)),
                      const SizedBox(height: 6),
                      Text(
                        _register
                            ? 'Create your student budget account.'
                            : 'Make every peso count.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 28),
                      if (_register) ...[
                        TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                                labelText: 'Display name',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your name.'
                                : null),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline)),
                          validator: (v) =>
                              v == null || !v.contains('@') || !v.contains('.')
                                  ? 'Enter a valid email.'
                                  : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _password,
                          obscureText: _hide,
                          decoration: InputDecoration(
                              labelText: 'Password (6+ characters)',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _hide = !_hide),
                                  icon: Icon(_hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined))),
                          validator: (v) => v == null || v.length < 6
                              ? 'Use at least 6 characters.'
                              : null),
                      if (_register) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _confirmPassword,
                            obscureText: _hide,
                            decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _hide = !_hide),
                                    icon: Icon(_hide
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined))),
                            validator: (v) => v == null || v != _password.text
                                ? 'Passwords do not match.'
                                : null),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(_register ? 'Create account' : 'Log in')),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _register = !_register;
                              _name.clear();
                              _email.clear();
                              _password.clear();
                              _confirmPassword.clear();
                            });
                          },
                          child: Text(_register
                              ? 'Already have an account? Log in'
                              : 'New here? Create an account')),
                      const Text(
                        'Classroom demo: use a practice password, not a real one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
