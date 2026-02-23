import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

// Dev-only screen to test authentication flow.

class TestLoginPage extends ConsumerStatefulWidget {
  const TestLoginPage({super.key});

  @override
  ConsumerState<TestLoginPage> createState() => _TestLoginPageState();
}

class _TestLoginPageState extends ConsumerState<TestLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).loginAsDocente(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go(AppRoutes.showcase);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueAsVisitor() {
    ref.read(authProvider.notifier).continueAsVisitor();
    context.go(AppRoutes.showcase);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Login / Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login como Docente'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _continueAsVisitor,
                    child: const Text('Continuar como Visitante'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              'Pantalla de prueba — solo modo debug.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
