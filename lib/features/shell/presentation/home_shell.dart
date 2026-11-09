import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/nav_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/create/presentation/create_screen.dart';
import 'package:tiktok_mobile/features/discover/presentation/discover_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';
import 'package:tiktok_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/profile_screen.dart';

/// The five tabs behind the floating nav bar. An IndexedStack keeps each
/// tab's scroll position and provider subscriptions alive across switches —
/// the feed does not restart when you come back from a profile.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialIndex;

  /// Tabs are built the first time they are opened and kept alive afterwards,
  /// so an unvisited tab never fires its providers (no profile fetch before
  /// you tap "You").
  late final Set<int> _visited = {widget.initialIndex};

  /// `/feed?tab=create` while the shell is already up (Studio's Upload)
  /// arrives as a new initial index on the same state.
  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) _go(widget.initialIndex);
  }

  /// How long the second back press has to exit the app.
  static const exitWindow = Duration(seconds: 2);

  DateTime? _lastBackAt;

  /// Back never leaves the app on the first press: from another tab it goes
  /// to the feed, and on the feed it asks for a second press within
  /// [exitWindow]. A stray swipe or tap costs nothing.
  void _onBack() {
    // Opened on top of another route: back just returns there.
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    if (_index != 0) {
      _go(0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBackAt;
    if (last != null && now.difference(last) < exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackAt = now;
    NowaToast.of(
      context,
    ).info('Press back again to exit', key: const Key('exit_app_toast'));
  }

  void _go(int i) => setState(() {
    _index = i;
    _visited.add(i);
  });

  @override
  Widget build(BuildContext context) {
    final screens = [
      // IndexedStack keeps the feed mounted behind the other tabs, so it has
      // to be told when it is off screen — otherwise the clip keeps playing
      // (and its audio keeps running) under Discover or Inbox.
      () => FeedScreen(visible: _index == 0, onOpenDiscover: () => _go(1)),
      () => const DiscoverScreen(),
      // Told when it is off screen too, so it lets go of the camera.
      () => CreateScreen(
        visible: _index == 2,
        onClose: () => _go(0),
        onPosted: () => _go(4),
      ),
      () => const InboxScreen(),
      () => const ProfileScreen(embedded: true),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: NowaColors.bg,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < screens.length; i++)
                  if (_visited.contains(i))
                    screens[i]()
                  else
                    const SizedBox.shrink(),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              // Its own count request, not the inbox list: the Inbox tab is not
              // built until it is opened, and the badge has to be right before
              // then. Signed out it answers 0 without a request. Unread
              // conversations count too: that list is live over the socket, so
              // a new message lights the tab up wherever the user is.
              child: NowaNavBar(
                index: _index,
                onTap: _go,
                unread:
                    (ref.watch(unreadCountProvider).valueOrNull ?? 0) +
                    ref.watch(unreadConversationsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
