import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
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
      appBar: AppBar(title: Text(widget.title)),
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
          return ListView.builder(
            key: const Key('user_list'),
            controller: _scrollController,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                key: Key('user_list_item_${user.userId}'),
                leading: CircleAvatar(
                  backgroundImage:
                      user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.displayName),
                subtitle: user.bio != null && user.bio!.isNotEmpty
                    ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                onTap: () => context.push('/profile/${user.userId}'),
              );
            },
          );
        },
      ),
    );
  }
}
