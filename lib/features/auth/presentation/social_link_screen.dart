import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

/// The step between "signed in at the provider" and "signed in here", shown
/// when that provider account's email address already belongs to an account of
/// ours and the provider never asserted the address is verified.
///
/// Deliberately names neither the account nor the address: whoever owns it
/// already knows both, and to anyone else printing them would confirm that a
/// stranger has an account here.
///
/// There is no resend: the code is minted by the login attempt, so tapping
/// "Continue with Facebook" again mails a fresh one (and kills this one).
class SocialLinkScreen extends ConsumerStatefulWidget {
  const SocialLinkScreen({super.key, required this.challenge});

  final SocialLinkRequired challenge;

  @override
  ConsumerState<SocialLinkScreen> createState() => _SocialLinkScreenState();
}

class _SocialLinkScreenState extends ConsumerState<SocialLinkScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requiresEmail =
          await ref.read(authStateProvider.notifier).confirmSocialLink(
                provider: widget.challenge.provider,
                token: widget.challenge.token,
                otp: _otpController.text.trim(),
              );
      // Nearly always /feed — the account we just linked into is the one that
      // owned the address. Nearly: the server answers a re-submitted code with
      // whatever account already holds this provider identity, and that one can
      // still be without an address of its own.
      if (mounted) context.go(requiresEmail ? '/add-email' : '/feed');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        widget.challenge.provider == 'google' ? 'Google' : 'Facebook';
    // No !_loading here: AuthPrimaryButton already refuses taps while it spins.
    final canSubmit = _otpController.text.trim().length == 6;

    return AuthScaffold(
      onBack: () => context.go('/login'),
      children: [
        const SizedBox(height: 16),
        const AuthTitle("Confirm it's you"),
        const SizedBox(height: 12),
        AuthHelperText(
          'That $provider account uses an email address that already has an '
          'account here. We emailed a 6-digit code to it — enter it to log in '
          'and connect $provider to that account.',
        ),
        const SizedBox(height: 28),
        AuthField.otp(
          key: const Key('social_link_otp_field'),
          controller: _otpController,
        ),
        const SizedBox(height: 24),
        if (_error != null) AuthErrorText(_error!),
        AuthPrimaryButton(
          key: const Key('social_link_submit_button'),
          label: 'Confirm and log in',
          loading: _loading,
          onPressed: canSubmit ? _confirm : null,
        ),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('social_link_cancel_button'),
          onPressed: _loading ? null : () => context.go('/login'),
          child: const Text('Use another way to log in'),
        ),
      ],
    );
  }
}
