import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

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
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: const Key('verify_email_field'),
                controller: _emailController,
                decoration: _fieldDecoration(colorScheme, 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('verify_otp_field'),
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(colorScheme, '6-digit code'),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_info != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_info!, style: TextStyle(color: colorScheme.primary)),
                ),
              ElevatedButton(
                key: const Key('verify_submit_button'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('verify_resend_button'),
                onPressed: _loading ? null : _resend,
                child: const Text('Resend code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
