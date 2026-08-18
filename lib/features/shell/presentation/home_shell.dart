import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/nav_bar.dart';
import 'package:tiktok_mobile/features/create/presentation/create_screen.dart';
import 'package:tiktok_mobile/features/discover/presentation/discover_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';
import 'package:tiktok_mobile/features/inbox/presentation/inbox_screen.dart';
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
      () => CreateScreen(onClose: () => _go(0)),
      () => const InboxScreen(),
      () => const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: NowaColors.bg,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < screens.length; i++)
                if (_visited.contains(i)) screens[i]() else const SizedBox.shrink(),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: NowaNavBar(index: _index, onTap: _go),
          ),
        ],
      ),
    );
  }
}
