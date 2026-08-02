import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(ColorScheme colorScheme, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Log in to TikTok',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('login_email_field'),
                controller: _emailController,
                decoration: _fieldDecoration(colorScheme, 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('login_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: _fieldDecoration(colorScheme, 'Password'),
              ),
              const SizedBox(height: 20),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    authState.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                key: const Key('login_submit_button'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authStateProvider.notifier).login(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Log in',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      key: const Key('login_forgot_password_button'),
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                    TextButton(
                      key: const Key('login_verify_email_button'),
                      onPressed: () => context.go('/verify-email'),
                      child: const Text('Verify email'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/register'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
