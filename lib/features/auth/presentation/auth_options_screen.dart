import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/social_sign_in.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/widgets/auth_ui.dart';

/// Entry screens for the auth flow: pick a provider first, then land on the
/// email form. Phone and Apple are intentionally absent — this app only
/// supports email, Google and Facebook.
///
/// Login and register share these handlers: to auth-service a social token is
/// just a token, and the same endpoint registers or signs in depending on
/// whether the provider identity is already known.
Future<void> _social(
  BuildContext context,
  WidgetRef ref,
  Future<bool> Function() signIn,
) async {
  try {
    final requiresEmail = await signIn();
    if (!context.mounted) return;
    context.go(requiresEmail ? '/add-email' : '/feed');
  } on SocialSignInCancelled {
    // Backing out of the provider sheet is not an error — say nothing.
  } on SocialSignInException catch (e) {
    if (context.mounted) _toast(context, e.message);
  } on AppException catch (e) {
    if (context.mounted) _toast(context, e.message);
  } catch (e) {
    // Anything else (a parse failure, say) would otherwise leave the button
    // looking dead: the provider sheet closes and nothing happens.
    if (context.mounted) _toast(context, 'Sign-in failed: $e');
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class LoginOptionsScreen extends ConsumerWidget {
  const LoginOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthScaffold(
      footer: AuthFooterBar(
        question: "Don't have an account?",
        actionLabel: 'Sign up',
        onTap: () => context.go('/register'),
      ),
      children: [
        const SizedBox(height: 24),
        const AuthTitle('Log in to TikTok', centered: true),
        const SizedBox(height: 32),
        AuthOptionButton(
          key: const Key('login_option_email'),
          icon: const Icon(Icons.person, size: 22, color: AuthColors.ink),
          label: 'Use email / username',
          onTap: () => context.go('/login/email'),
        ),
        const SizedBox(height: 12),
        AuthOptionButton(
          key: const Key('login_option_facebook'),
          icon: const FacebookGlyph(),
          label: 'Continue with Facebook',
          onTap: () => _social(
            context,
            ref,
            ref.read(authStateProvider.notifier).loginWithFacebook,
          ),
        ),
        const SizedBox(height: 12),
        AuthOptionButton(
          key: const Key('login_option_google'),
          icon: const GoogleGlyph(),
          label: 'Continue with Google',
          onTap: () => _social(
            context,
            ref,
            ref.read(authStateProvider.notifier).loginWithGoogle,
          ),
        ),
        const SizedBox(height: 40),
        const AuthTermsText(),
      ],
    );
  }
}

class RegisterOptionsScreen extends ConsumerWidget {
  const RegisterOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthScaffold(
      onBack: () => context.go('/login'),
      footer: AuthFooterBar(
        question: 'Already have an account?',
        actionLabel: 'Log in',
        onTap: () => context.go('/login'),
      ),
      children: [
        const SizedBox(height: 8),
        const AuthTitle('Sign up for TikTok', centered: true),
        const SizedBox(height: 32),
        AuthOptionButton(
          key: const Key('register_option_email'),
          icon: const Icon(Icons.email, size: 22, color: AuthColors.ink),
          label: 'Continue with email',
          onTap: () => context.go('/register/email'),
        ),
        const SizedBox(height: 12),
        AuthOptionButton(
          key: const Key('register_option_facebook'),
          icon: const FacebookGlyph(),
          label: 'Continue with Facebook',
          onTap: () => _social(
            context,
            ref,
            ref.read(authStateProvider.notifier).loginWithFacebook,
          ),
        ),
        const SizedBox(height: 12),
        AuthOptionButton(
          key: const Key('register_option_google'),
          icon: const GoogleGlyph(),
          label: 'Continue with Google',
          onTap: () => _social(
            context,
            ref,
            ref.read(authStateProvider.notifier).loginWithGoogle,
          ),
        ),
        const SizedBox(height: 40),
        const AuthTermsText(),
      ],
    );
  }
}
