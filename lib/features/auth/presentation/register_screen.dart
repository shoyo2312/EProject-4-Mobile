import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_usernameController, _emailController, _passwordController]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  // Registering does NOT sign the user in — the account has emailVerified =
  // false and /login would answer 403 until the OTP is confirmed. Send the
  // user straight to the OTP screen instead (auth doc 3.1).
  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).register(
            email: email,
            password: _passwordController.text,
            username: _usernameController.text.trim(),
          );
      if (mounted) context.go('/verify-email', extra: email);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return AuthScaffold(
      onBack: () => context.go('/register'),
      footer: AuthFooterBar(
        question: 'Already have an account?',
        actionLabel: 'Log in',
        onTap: () => context.go('/login'),
      ),
      children: [
        const SizedBox(height: 8),
        const AuthTitle('Sign up with email'),
        const SizedBox(height: 28),
        AuthField(
          key: const Key('register_username_field'),
          controller: _usernameController,
          hint: 'Username',
        ),
        const SizedBox(height: 12),
        AuthField(
          key: const Key('register_email_field'),
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AuthField(
          key: const Key('register_password_field'),
          controller: _passwordController,
          hint: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        const AuthHelperText(
          "You'll receive a 6-digit verification code by email. Your account "
          'stays inactive until the code is confirmed.',
        ),
        const SizedBox(height: 28),
        if (_error != null) AuthErrorText(_error!),
        AuthPrimaryButton(
          key: const Key('register_submit_button'),
          label: 'Sign up',
          loading: _loading,
          onPressed: canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
