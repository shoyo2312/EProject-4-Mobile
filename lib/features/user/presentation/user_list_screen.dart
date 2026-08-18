import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Reusable list screen for followers/following/blocked/muted — all four
/// share the same `Page<UserProfileResponse>` shape and infinite-scroll
/// pagination behavior (doc section 2, 3.6/3.7/3.10/3.13).
class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key, required this.title, required this.args});

  final String title;
  final UserListArgs args;

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(userListNotifierProvider(widget.args).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(userListNotifierProvider(widget.args));
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(title: widget.title),
      body: listState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userListNotifierProvider(widget.args)),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const ErrorView(message: 'Nothing here yet');
          }
          return ListView.separated(
            key: const Key('user_list'),
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final user = users[index];
              final hasBio = user.bio != null && user.bio!.isNotEmpty;
              return GestureDetector(
                key: Key('user_list_item_${user.userId}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/profile/${user.userId}'),
                child: Row(
                  children: [
                    NowaAvatar(url: user.avatarUrl, size: 46, radius: 16, border: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: sora(size: 14)),
                          if (hasBio) ...[
                            const SizedBox(height: 3),
                            Text(
                              user.bio!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: work(
                                size: 12.5,
                                height: 1.3,
                                color: NowaColors.text.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${compact(user.followerCount)} followers',
                      style: work(
                        size: 11.5,
                        height: 1,
                        color: NowaColors.text.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
