import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_comment_tile.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// Every comment on the creator's videos in one place: filter by video or
/// held-for-review, search, and reply, like, approve or delete in the row.
class StudioCommentsScreen extends ConsumerStatefulWidget {
  const StudioCommentsScreen({super.key, this.initialVideoId});

  /// Opens filtered to this video's comments.
  final String? initialVideoId;

  @override
  ConsumerState<StudioCommentsScreen> createState() =>
      _StudioCommentsScreenState();
}

class _StudioCommentsScreenState extends ConsumerState<StudioCommentsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  String? get _key => widget.initialVideoId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(studioInboxProvider(_key).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  InboxQuery get _query => ref.read(studioInboxFilterProvider(_key));

  void _setQuery(InboxQuery query) =>
      ref.read(studioInboxFilterProvider(_key).notifier).set(query);

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _setQuery(_query.copyWith(q: text)),
    );
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final toast = NowaToast.of(context);
    try {
      await action();
      if (done != null) toast.success(done);
    } on AppException catch (e) {
      toast.error(e.message);
    }
  }

  Future<void> _confirmDelete(CommentModel comment) async {
    final held = comment.status == CommentStatus.held;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: NowaColors.surface,
        title: Text(held ? 'Reject this comment?' : 'Delete this comment?',
            style: sora(size: 16)),
        content: Text(
          held
              ? "It's deleted and never shown to anyone."
              : "It's removed from your video for everyone.",
          style: work(size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text('Cancel', style: sora(size: 13, color: NowaColors.dim)),
          ),
          TextButton(
            key: const Key('studio_comment_delete_confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(held ? 'Reject' : 'Delete',
                style: sora(size: 13, color: NowaColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => ref.read(studioInboxProvider(_key).notifier).delete(comment),
      done: held ? 'Comment rejected' : 'Comment deleted',
    );
  }

  Future<void> _reply(CommentModel comment) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReplySheet(comment: comment),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    await _run(
      () async {
        final created = await ref
            .read(studioInboxProvider(_key).notifier)
            .reply(comment, text.trim());
        if (created.status == CommentStatus.held) {
          throw const UnknownException(
            'Your reply is held for review by your own comment filters.',
          );
        }
      },
      done: 'Reply posted',
    );
  }

  Future<void> _pickVideo() async {
    final picked = await showModalBottomSheet<_VideoPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _VideoPicker(),
    );
    if (picked == null) return;
    final q = _query;
    // Sort and replied only mean something within one video.
    _setQuery(picked.videoId == null
        ? InboxQuery(heldOnly: q.heldOnly, q: q.q)
        : q.copyWith(videoId: picked.videoId));
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(studioInboxFilterProvider(_key));
    final comments = ref.watch(studioInboxProvider(_key));
    final videos = ref.watch(studioVideoCacheProvider);
    final pickedTitle = query.videoId == null
        ? 'All videos'
        : (videos[query.videoId]?.title ?? 'One video');

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Comments'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const Key('studio_comments_search'),
              controller: _search,
              onChanged: _onSearch,
              style: work(size: 13.5),
              decoration: InputDecoration(
                hintText: 'Search comments',
                hintStyle: work(size: 13.5, color: NowaColors.dim),
                prefixIcon: const Icon(Icons.search, color: NowaColors.dim, size: 20),
                filled: true,
                fillColor: NowaColors.surfaceHigh,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // A handful of chips: a plain scrolling row, all of them built.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Chip2(
                  key: const Key('studio_comments_video'),
                  label: '▾  ${pickedTitle.length > 24 ? '${pickedTitle.substring(0, 24)}…' : pickedTitle}',
                  active: query.videoId != null,
                  onTap: _pickVideo,
                ),
                const SizedBox(width: 8),
                Chip2(
                  key: const Key('studio_comments_held'),
                  label: 'Held for review',
                  active: query.heldOnly,
                  onTap: () => _setQuery(query.copyWith(heldOnly: !query.heldOnly)),
                ),
                if (query.videoId != null) ...[
                  for (final s in InboxSort.values) ...[
                    const SizedBox(width: 8),
                    Chip2(
                      label: s.label,
                      active: query.sort == s,
                      onTap: () => _setQuery(query.copyWith(sort: s)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Chip2(
                    label: 'Not replied',
                    active: query.replied == false,
                    onTap: () => _setQuery(query.copyWith(
                      replied: query.replied == false ? null : false,
                    )),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: NowaColors.accent,
              onRefresh: () =>
                  studioRefresh(ref.refresh(studioInboxProvider(_key).future)),
              child: comments.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(studioInboxProvider(_key)),
                ),
                data: (items) => items.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              query.heldOnly
                                  ? 'No comments waiting for review.'
                                  : 'No comments here yet.',
                              textAlign: TextAlign.center,
                              style: work(size: 13, color: NowaColors.dim),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: NowaColors.hairline),
                        itemBuilder: (context, i) {
                          final c = items[i];
                          final inbox = ref.read(studioInboxProvider(_key).notifier);
                          return StudioCommentTile(
                            key: Key('studio_comment_${c.id}'),
                            comment: c,
                            onLike: () => _run(() => inbox.toggleLike(c)),
                            onReply: () => _reply(c),
                            onApprove: () =>
                                _run(() => inbox.approve(c), done: 'Comment approved'),
                            onDelete: () => _confirmDelete(c),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.comment});

  final CommentModel comment;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reply to', style: work(size: 12, color: NowaColors.dim)),
              const SizedBox(height: 2),
              Text(
                widget.comment.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: work(size: 13.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('studio_reply_field'),
                      controller: _text,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 150,
                      style: work(size: 14),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Add a reply…',
                        hintStyle: work(size: 13.5, color: NowaColors.dim),
                        filled: true,
                        fillColor: NowaColors.surfaceHigh,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('studio_reply_send'),
                    onPressed: _text.text.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_text.text),
                    icon: const Icon(Icons.send_rounded, color: NowaColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picker's answer: a video, or "all" (a null id).
class _VideoPick {
  const _VideoPick(this.videoId);
  final String? videoId;
}

class _VideoPicker extends ConsumerWidget {
  const _VideoPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(studioPickableVideosProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Choose a video', style: sora(size: 15))),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(const _VideoPick(null)),
                    child: Text('All videos',
                        style: sora(size: 12.5, color: NowaColors.accent)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: videos.when(
                loading: () => const SizedBox(height: 160, child: LoadingView()),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(studioPickableVideosProvider),
                ),
                data: (list) => ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (context, i) => StudioPostTile(
                    video: list[i],
                    onTap: () {
                      ref.read(studioVideoCacheProvider.notifier).put(list[i]);
                      Navigator.of(context).pop(_VideoPick(list[i].id));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
