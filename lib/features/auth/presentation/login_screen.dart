import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The CTA stays pink/inert until both fields have something in them.
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // 403 EMAIL_NOT_VERIFIED means the password was correct and only the OTP
    // step is missing, so it gets its own destination instead of being shown
    // as "wrong credentials" (auth doc 3.2).
    ref.listen(authStateProvider, (_, next) {
      final error = next.error;
      if (error is ServerException && error.code == 'EMAIL_NOT_VERIFIED') {
        context.go('/verify-email', extra: _emailController.text.trim());
      }
    });

    final canSubmit = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return AuthScaffold(
      onBack: () => context.go('/login'),
      footer: AuthFooterBar(
        question: "Don't have an account?",
        actionLabel: 'Sign up',
        onTap: () => context.go('/register'),
      ),
      children: [
        const SizedBox(height: 8),
        const AuthTitle('Log in', centered: true),
        const SizedBox(height: 32),
        AuthField(
          key: const Key('login_email_field'),
          controller: _emailController,
          hint: 'Email or username',
        ),
        const SizedBox(height: 12),
        AuthField(
          key: const Key('login_password_field'),
          controller: _passwordController,
          hint: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        AuthLink(
          key: const Key('login_forgot_password_button'),
          label: 'Forgot password?',
          align: Alignment.centerLeft,
          onTap: () => context.go('/forgot-password'),
        ),
        const SizedBox(height: 24),
        if (authState.hasError) AuthErrorText(authState.error.toString()),
        AuthPrimaryButton(
          key: const Key('login_submit_button'),
          label: 'Log in',
          loading: authState.isLoading,
          onPressed: canSubmit
              ? () => ref.read(authStateProvider.notifier).login(
                    email: _emailController.text,
                    password: _passwordController.text,
                  )
              : null,
        ),
        const SizedBox(height: 16),
        AuthLink(
          key: const Key('login_verify_email_button'),
          label: 'Verify email',
          onTap: () => context.go('/verify-email'),
        ),
      ],
    );
  }
}
