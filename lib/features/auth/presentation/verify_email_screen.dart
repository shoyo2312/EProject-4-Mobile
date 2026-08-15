import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final _emailController = TextEditingController(text: widget.email);
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmail(
            email: _emailController.text,
            otp: _otpController.text,
          );
      if (mounted) context.go('/login');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerification(_emailController.text);
      setState(() => _info = 'Verification code sent.');
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
        const AuthTitle('Verify your email'),
        const SizedBox(height: 12),
        const AuthHelperText(
          'Your account stays inactive until the 6-digit code we emailed you '
          'is confirmed.',
        ),
        const SizedBox(height: 28),
        AuthField(
          key: const Key('verify_email_field'),
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AuthField(
          key: const Key('verify_otp_field'),
          controller: _otpController,
          hint: '6-digit code',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        if (_error != null) AuthErrorText(_error!),
        if (_info != null) AuthInfoText(_info!),
        AuthPrimaryButton(
          key: const Key('verify_submit_button'),
          label: 'Verify',
          loading: _loading,
          onPressed: _loading ? null : _verify,
        ),
        const SizedBox(height: 16),
        AuthLink(
          key: const Key('verify_resend_button'),
          label: 'Resend code',
          accent: true,
          onTap: _loading ? () {} : _resend,
        ),
      ],
    );
  }
}
