import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

/// Reached after a social login that returned requiresEmail — Facebook accounts
/// arrive with no address at all. The session already works, so this is
/// skippable; without an address though the account cannot be recovered if the
/// provider account is lost.
class AddEmailScreen extends ConsumerStatefulWidget {
  const AddEmailScreen({super.key});

  @override
  ConsumerState<AddEmailScreen> createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends ConsumerState<AddEmailScreen> {
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
      final email = _emailController.text.trim();
      await ref.read(authRepositoryProvider).addEmail(email);
      // The address is claimed but unverified; the OTP flow is the same one
      // email sign-ups use.
      if (mounted) context.go('/verify-email', extra: email);
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
      children: [
        const SizedBox(height: 16),
        const AuthTitle('Add your email'),
        const SizedBox(height: 12),
        const AuthHelperText(
          'Your account has no email address yet. Add one so you can recover '
          'the account and receive notifications.',
        ),
        const SizedBox(height: 28),
        AuthField(
          key: const Key('add_email_field'),
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        if (_error != null) AuthErrorText(_error!),
        AuthPrimaryButton(
          key: const Key('add_email_submit_button'),
          label: 'Send code',
          loading: _loading,
          onPressed: canSubmit ? _submit : null,
        ),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('add_email_skip_button'),
          onPressed: _loading ? null : () => context.go('/feed'),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}
