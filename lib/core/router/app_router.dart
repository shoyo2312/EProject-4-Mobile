import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/devices_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/qr_confirm_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/qr_scan_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/add_email_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_options_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/login_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/register_screen.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/social_link_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/message_requests_screen.dart';
import 'package:tiktok_mobile/features/shell/presentation/home_shell.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_analytics_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_comments_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_edit_post_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_home_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_inspiration_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_posts_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_video_analytics_screen.dart';
import 'package:tiktok_mobile/features/story/presentation/story_composer_screen.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_viewer_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_link_screen.dart';
import 'package:tiktok_mobile/features/notification/presentation/notifications_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/daily_screen_time_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/keyword_filters_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/screen_time_summary_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/sleep_hours_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/comment_filters_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/follow_requests_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/edit_profile_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/profile_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/user_list_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

// Reachable without being logged in (or, for verify-email, while logged in
// with an unverified account) — excluded from the logged-in/out redirect.
const _authRoutes = {
  '/login',
  '/login/email',
  '/register',
  '/register/email',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
  // Reached from a *failed* social login, so nobody is signed in yet.
  '/social-link',
};

// The feed is the landing page for everyone, signed in or not, so it is the
// one non-auth route a guest may open. Actions reached from it (commenting,
// profile) still bounce to /login.
const _guestRoutes = {..._authRoutes, '/feed'};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (!isLoggedIn && !_guestRoutes.contains(state.matchedLocation)) {
        return '/login';
      }
      if (isLoggedIn &&
          isAuthRoute &&
          state.matchedLocation != '/verify-email') {
        return '/feed';
      }
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      // /login and /register are the provider pickers (email, Facebook,
      // Google); the email forms live one level down.
      GoRoute(path: '/login', builder: (_, _) => const LoginOptionsScreen()),
      GoRoute(path: '/login/email', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterOptionsScreen(),
      ),
      GoRoute(
        path: '/register/email',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(email: state.extra as String?),
      ),
      // Deliberately not in _authRoutes: it is only reachable *after* a social
      // login, so the logged-in redirect must leave it alone.
      GoRoute(path: '/add-email', builder: (_, _) => const AddEmailScreen()),
      // The challenge is passed as an object, never as a query parameter: it
      // carries the provider token, which must not end up in a URL. Without
      // one there is nothing to confirm — an app restart lands back at /login.
      GoRoute(
        path: '/social-link',
        redirect: (_, state) =>
            state.extra is SocialLinkRequired ? null : '/login',
        builder: (_, state) =>
            SocialLinkScreen(challenge: state.extra! as SocialLinkRequired),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            ResetPasswordScreen(email: state.extra as String?),
      ),
      // The five tabs (feed, discover, create, inbox, you) live behind one
      // route — the nav bar switches an IndexedStack, it does not navigate.
      // `?tab=create` lands on the Create tab (Studio's Upload button).
      GoRoute(
        path: '/feed',
        builder: (_, state) => HomeShell(
          initialIndex: state.uri.queryParameters['tab'] == 'create' ? 2 : 0,
        ),
      ),
      // One video by id; `?comments=1` opens its comment sheet on arrival
      // (a comment notification).
      GoRoute(
        path: '/video/:videoId',
        builder: (_, state) => VideoLinkScreen(
          videoId: state.pathParameters['videoId']!,
          openComments: state.uri.queryParameters['comments'] == '1',
        ),
      ),
      // Both carry an object, not ids in the path: the composer needs the
      // picked file, the viewer the groups already loaded. Without one (an
      // app restart, a stray deep link) there is nothing to show.
      GoRoute(
        path: '/stories/new',
        redirect: (_, state) => state.extra is StoryDraft ? null : '/feed',
        builder: (_, state) =>
            StoryComposerScreen(draft: state.extra! as StoryDraft),
      ),
      GoRoute(
        path: '/stories/view',
        redirect: (_, state) => state.extra is StoryViewerArgs ? null : '/feed',
        builder: (_, state) =>
            StoryViewerScreen(args: state.extra! as StoryViewerArgs),
      ),
      // The thread list itself is the Inbox tab; its "Activity" entry opens
      // the notifications.
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      // Before the thread route, which would read "requests" as an id.
      GoRoute(
        path: '/messages/requests',
        builder: (_, _) => const MessageRequestsScreen(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) =>
            ProfileScreen(userId: state.pathParameters['userId']),
      ),
      GoRoute(
        path: '/profile/:userId/followers',
        builder: (_, state) => UserListScreen(
          title: 'Followers',
          args: UserListArgs(
            UserListType.followers,
            state.pathParameters['userId'],
          ),
        ),
      ),
      GoRoute(
        path: '/profile/:userId/following',
        builder: (_, state) => UserListScreen(
          title: 'Following',
          args: UserListArgs(
            UserListType.following,
            state.pathParameters['userId'],
          ),
        ),
      ),
      GoRoute(
        path: '/me/blocked',
        builder: (_, _) => const UserListScreen(
          title: 'Blocked users',
          args: UserListArgs(UserListType.blocked),
        ),
      ),
      GoRoute(path: '/me/devices', builder: (_, _) => const DevicesScreen()),
      // Web sign-in by QR. Signed-in only (not in _guestRoutes): approving a
      // browser is this account's decision.
      GoRoute(path: '/me/qr-login', builder: (_, _) => const QrScanScreen()),
      GoRoute(
        path: '/me/qr-login/confirm',
        // The claimed code travels as an object; a reload without it goes
        // back to the camera rather than confirming nothing.
        redirect: (_, state) =>
            state.extra is QrLoginConfirmArgs ? null : '/me/qr-login',
        builder: (_, state) =>
            QrConfirmScreen(args: state.extra! as QrLoginConfirmArgs),
      ),
      GoRoute(
        path: '/me/comment-filters',
        builder: (_, _) => const CommentFiltersScreen(),
      ),
      GoRoute(
        path: '/me/follow-requests',
        builder: (_, _) => const FollowRequestsScreen(),
      ),
      // Settings and privacy. Every page under /settings is left out of the
      // daily screen-time lock, so the limit can always still be changed.
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/settings/screen-time/daily',
        builder: (_, _) => const DailyScreenTimeScreen(),
      ),
      GoRoute(
        path: '/settings/screen-time/sleep',
        builder: (_, _) => const SleepHoursSettingsScreen(),
      ),
      GoRoute(
        // ?week=YYYY-MM-DD (a Monday) from a weekly screen-time notification.
        path: '/settings/screen-time/summary',
        builder: (_, state) => ScreenTimeSummaryScreen(
          initialWeek: state.uri.queryParameters['week'],
        ),
      ),
      GoRoute(
        path: '/settings/keyword-filters',
        builder: (_, _) => const KeywordFiltersScreen(),
      ),
      GoRoute(
        path: '/me/muted',
        builder: (_, _) => const UserListScreen(
          title: 'Muted users',
          args: UserListArgs(UserListType.muted),
        ),
      ),
      // Nowa Studio — the signed-in creator's own numbers and content, so
      // none of it is open to guests.
      GoRoute(path: '/studio', builder: (_, _) => const StudioHomeScreen()),
      GoRoute(
        // ?tab=0|1|2 (overview, content, viewers), ?metric=views|likes|…
        path: '/studio/analytics',
        builder: (_, state) => StudioAnalyticsScreen(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
          initialMetric: state.uri.queryParameters['metric'],
        ),
      ),
      GoRoute(
        path: '/studio/analytics/:videoId',
        builder: (_, state) => StudioVideoAnalyticsScreen(
          videoId: state.pathParameters['videoId']!,
        ),
      ),
      GoRoute(
        path: '/studio/posts',
        builder: (_, _) => const StudioPostsScreen(),
      ),
      GoRoute(
        path: '/studio/posts/:videoId/edit',
        builder: (_, state) => StudioEditPostScreen(
          videoId: state.pathParameters['videoId']!,
        ),
      ),
      GoRoute(
        // ?videoId= opens filtered to that video.
        path: '/studio/comments',
        builder: (_, state) => StudioCommentsScreen(
          initialVideoId: state.uri.queryParameters['videoId'],
        ),
      ),
      GoRoute(
        path: '/studio/inspiration',
        builder: (_, _) => const StudioInspirationScreen(),
      ),
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
