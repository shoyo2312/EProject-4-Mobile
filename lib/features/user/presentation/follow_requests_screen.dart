import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// People asking to follow this private account (user doc 3.16). Confirm and
/// Delete both take the row away at once; a refusal other than "already
/// handled" puts it back.
class FollowRequestsScreen extends ConsumerStatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  ConsumerState<FollowRequestsScreen> createState() =>
      _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends ConsumerState<FollowRequestsScreen> {
  static const _args = UserListArgs(UserListType.followRequests);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(userListNotifierProvider(_args).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _answer(UserProfileModel user, {required bool approve}) async {
    final messenger = ScaffoldMessenger.of(context);
    final list = ref.read(userListNotifierProvider(_args).notifier);
    final repo = ref.read(userRepositoryProvider);
    list.remove(user.userId);
    try {
      if (approve) {
        await repo.approveFollowRequest(user.userId);
        // A new follower: the counters on my profile moved.
        ref.invalidate(myProfileProvider);
      } else {
        await repo.declineFollowRequest(user.userId);
      }
    } on ServerException catch (e) {
      // Withdrawn, or answered on another device: the row is right to go.
      if (e.code == 'FOLLOW_REQUEST_NOT_FOUND') return;
      ref.invalidate(userListNotifierProvider(_args));
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      ref.invalidate(userListNotifierProvider(_args));
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userListNotifierProvider(_args));
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Follow requests'),
      body: state.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userListNotifierProvider(_args)),
        ),
        data: (users) => users.isEmpty
            ? const ErrorView(message: 'No one is waiting for your approval.')
            : ListView.separated(
                key: const Key('follow_requests_list'),
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Row(
                    key: Key('follow_request_${user.userId}'),
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/profile/${user.userId}'),
                          child: Row(
                            children: [
                              NowaAvatar(
                                url: user.avatarUrl,
                                size: 46,
                                radius: 16,
                                border: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: sora(size: 14),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'requested to follow you',
                                      style: work(
                                        size: 12,
                                        color: NowaColors.dim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: NowaButton(
                          key: Key('follow_request_confirm_${user.userId}'),
                          label: 'Confirm',
                          height: 36,
                          onTap: () => _answer(user, approve: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 88,
                        child: NowaButton(
                          key: Key('follow_request_delete_${user.userId}'),
                          label: 'Delete',
                          height: 36,
                          filled: false,
                          onTap: () => _answer(user, approve: false),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
