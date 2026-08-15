import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailController.text;
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) context.go('/reset-password', extra: email);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _emailController.text.trim().isNotEmpty;

    return AuthScaffold(
      onBack: () => context.go('/login'),
      children: [
        const SizedBox(height: 16),
        const AuthTitle('Forgot password'),
        const SizedBox(height: 12),
        const AuthHelperText(
          'Enter the email on your account and we will send a 6-digit code to '
          'reset your password.',
        ),
        const SizedBox(height: 28),
        AuthField(
          key: const Key('forgot_email_field'),
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        if (_error != null) AuthErrorText(_error!),
        AuthPrimaryButton(
          key: const Key('forgot_submit_button'),
          label: 'Send code',
          loading: _loading,
          onPressed: canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
