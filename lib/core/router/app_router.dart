import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/login_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/register_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

// Reachable without being logged in (or, for verify-email, while logged in
// with an unverified account) — excluded from the logged-in/out redirect.
const _authRoutes = {
  '/login',
  '/register',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/verify-email') {
        return '/feed';
      }
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(email: state.extra as String?),
      ),
      GoRoute(path: '/feed', builder: (_, _) => const FeedScreen()),
    ],
  );
});

/// Bridges Riverpod's authStateProvider changes into go_router's
/// ChangeNotifier-based refresh mechanism.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}
