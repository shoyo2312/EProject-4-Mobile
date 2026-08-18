import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _emailController = TextEditingController(text: widget.email);
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text,
            otp: _otpController.text,
            newPassword: _newPasswordController.text,
          );
      // Every session died server-side, this device included, and the
      // repository already dropped the local tokens — drop the cached user
      // too so the router stops treating us as signed in (auth doc 3.9).
      ref.invalidate(authStateProvider);
      if (mounted) context.go('/login');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.go('/login'),
      children: [
        const SizedBox(height: 16),
        const AuthTitle('Reset password'),
        const SizedBox(height: 28),
        AuthField(
          key: const Key('reset_email_field'),
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AuthField.otp(
          key: const Key('reset_otp_field'),
          controller: _otpController,
        ),
        const SizedBox(height: 12),
        AuthField(
          key: const Key('reset_new_password_field'),
          controller: _newPasswordController,
          hint: 'New password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        const AuthHelperText(
          'Resetting the password signs you out everywhere, including this '
          'device.',
        ),
        const SizedBox(height: 28),
        if (_error != null) AuthErrorText(_error!),
        AuthPrimaryButton(
          key: const Key('reset_submit_button'),
          label: 'Reset password',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
