import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// The user-facing text for a failed change to a video.
String studioErrorText(AppException e) {
  if (e is ServerException) {
    switch (e.code) {
      case 'PIN_LIMIT_REACHED':
        return 'You can pin up to 3 videos. Unpin one first.';
      case 'NOT_VIDEO_OWNER':
      case 'VIDEO_NOT_FOUND':
        return 'This video is gone, or it is not yours.';
      case 'VIDEO_CAPTION_HELD':
        return 'This caption needs a review before it can go live. Try different wording.';
    }
    if (e.code?.startsWith('VIDEO_') == true && e.code!.endsWith('_REJECTED')) {
      return "This caption breaks the community guidelines and can't be saved.";
    }
  }
  return e.message;
}

/// Every video the creator has posted, in any status, with search, filters
/// and the actions TikTok Studio's Posts table offers.
class StudioPostsScreen extends ConsumerStatefulWidget {
  const StudioPostsScreen({super.key});

  @override
  ConsumerState<StudioPostsScreen> createState() => _StudioPostsScreenState();
}

class _StudioPostsScreenState extends ConsumerState<StudioPostsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(studioPostsProvider.notifier).loadMore();
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

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final filter = ref.read(studioPostFilterProvider.notifier);
      filter.set(ref.read(studioPostFilterProvider).copyWith(q: text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(studioPostFilterProvider);
    final posts = ref.watch(studioPostsProvider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Posts'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('studio_posts_search'),
                    controller: _search,
                    onChanged: _onSearch,
                    style: work(size: 13.5),
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Search your posts',
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
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('studio_posts_filter'),
                  tooltip: 'Filter and sort',
                  onPressed: () => _openFilters(context),
                  icon: Badge(
                    isLabelVisible: query.isFiltered,
                    backgroundColor: NowaColors.accent,
                    smallSize: 8,
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sorted by ${query.sort.label.toLowerCase()}, '
                '${query.descending ? 'high to low' : 'low to high'}',
                style: work(size: 11.5, color: NowaColors.dim),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: NowaColors.accent,
              onRefresh: () => studioRefresh(ref.refresh(studioPostsProvider.future)),
              child: posts.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(studioPostsProvider),
                ),
                data: (videos) => videos.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              query.isFiltered || query.q.isNotEmpty
                                  ? 'No posts match these filters.'
                                  : 'No posts yet.',
                              textAlign: TextAlign.center,
                              style: work(size: 13, color: NowaColors.dim),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: videos.length,
                        itemBuilder: (context, i) => StudioPostTile(
                          key: Key('studio_post_${videos[i].id}'),
                          video: videos[i],
                          onTap: () => showStudioPostActions(context, ref, videos[i]),
                          trailing: const Padding(
                            padding: EdgeInsets.only(left: 4, top: 4),
                            child: Icon(Icons.more_vert, color: NowaColors.dim, size: 20),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final picked = await showModalBottomSheet<StudioPostQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(initial: ref.read(studioPostFilterProvider)),
    );
    if (picked != null) ref.read(studioPostFilterProvider.notifier).set(picked);
  }
}

/// The actions on one of the creator's videos. Shared by every list that
/// shows one.
Future<void> showStudioPostActions(
  BuildContext context,
  WidgetRef ref,
  VideoModel video,
) async {
  final note = statusNote(video.status);
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) {
      void choose(String value) => Navigator.of(sheet).pop(value);
      Widget tile(String value, IconData icon, String label, {bool danger = false}) =>
          ListTile(
            key: Key('studio_action_$value'),
            leading: Icon(icon, color: danger ? NowaColors.danger : Colors.white),
            title: Text(
              label,
              style: work(size: 14, color: danger ? NowaColors.danger : NowaColors.text),
            ),
            onTap: () => choose(value),
          );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  video.title.isEmpty ? 'Untitled' : video.title,
                  style: sora(size: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isNotEmpty || video.takedownReason != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                  child: Text(
                    [note, ?video.takedownReason].where((s) => s.isNotEmpty).join(' '),
                    style: work(size: 12, color: NowaColors.danger),
                  ),
                ),
              if (video.status == VideoStatus.published)
                tile('watch', Icons.play_circle_outline, 'Watch'),
              tile('analytics', Icons.insights_outlined, 'View analytics'),
              tile('edit', Icons.edit_outlined, 'Edit post'),
              tile('comments', Icons.chat_bubble_outline, 'Manage comments'),
              if (video.status == VideoStatus.published)
                tile(
                  'pin',
                  video.pinnedAt == null ? Icons.push_pin_outlined : Icons.push_pin,
                  video.pinnedAt == null ? 'Pin to profile' : 'Unpin from profile',
                ),
              const Divider(height: 1, color: NowaColors.hairline),
              tile('delete', Icons.delete_outline, 'Delete', danger: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final editor = ref.read(studioEditorProvider);
  switch (action) {
    case 'watch':
      context.push('/video/${video.id}');
    case 'analytics':
      context.push('/studio/analytics/${video.id}');
    case 'edit':
      context.push('/studio/posts/${video.id}/edit');
    case 'comments':
      context.push('/studio/comments?videoId=${video.id}');
    case 'pin':
      try {
        final updated = await editor.setPinned(video.id, video.pinnedAt == null);
        messenger.showSnackBar(SnackBar(
          content: Text(updated.pinnedAt == null ? 'Unpinned' : 'Pinned to your profile'),
        ));
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(studioErrorText(e))));
      }
    case 'delete':
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          backgroundColor: NowaColors.surface,
          title: Text('Delete this post?', style: sora(size: 16)),
          content: Text(
            "It's removed for good, with its likes and comments. This can't be undone.",
            style: work(size: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text('Cancel', style: sora(size: 13, color: NowaColors.dim)),
            ),
            TextButton(
              key: const Key('studio_delete_confirm'),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text('Delete', style: sora(size: 13, color: NowaColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await editor.delete(video.id);
        messenger.showSnackBar(const SnackBar(content: Text('Post deleted')));
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(studioErrorText(e))));
      }
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final StudioPostQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late StudioPostQuery _query = widget.initial;

  List<T> _toggle<T>(List<T> list, T value) =>
      list.contains(value)
          ? [for (final x in list) if (x != value) x]
          : [...list, value];

  bool _hasStatus(List<String> group) => group.every(_query.statuses.contains);

  void _toggleStatus(List<String> group) {
    final next = _hasStatus(group)
        ? [for (final s in _query.statuses) if (!group.contains(s)) s]
        : [..._query.statuses, ...group.where((s) => !_query.statuses.contains(s))];
    setState(() => _query = _query.copyWith(statuses: next));
  }

  @override
  Widget build(BuildContext context) {
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SectionLabel(text.toUpperCase()),
        );
    Widget chip(String text, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Chip2(label: text, active: active, onTap: onTap),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter and sort', style: sora(size: 16)),
            label('Sort by'),
            Wrap(
              children: [
                for (final s in StudioPostSort.values)
                  chip(s.label, _query.sort == s,
                      () => setState(() => _query = _query.copyWith(sort: s))),
              ],
            ),
            Wrap(
              children: [
                chip('High to low', _query.descending,
                    () => setState(() => _query = _query.copyWith(descending: true))),
                chip('Low to high', !_query.descending,
                    () => setState(() => _query = _query.copyWith(descending: false))),
              ],
            ),
            label('Status'),
            Wrap(
              children: [
                for (final (text, group) in statusFilters)
                  chip(text, _hasStatus(group), () => _toggleStatus(group)),
              ],
            ),
            label('Who can watch'),
            Wrap(
              children: [
                for (final v in studioVisibilities)
                  chip(
                    visibilityLabel(v),
                    _query.visibilities.contains(visibilityWire(v)),
                    () => setState(() => _query = _query.copyWith(
                          visibilities: _toggle(_query.visibilities, visibilityWire(v)),
                        )),
                  ),
              ],
            ),
            label('Views'),
            Wrap(
              children: [
                for (final r in CountRange.values)
                  chip(
                    r.label,
                    _query.views.contains(r),
                    () => setState(() => _query = _query.copyWith(views: _toggle(_query.views, r))),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NowaButton(
                    label: 'Reset',
                    filled: false,
                    onTap: () => setState(() => _query = StudioPostQuery(q: _query.q)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NowaButton(
                    key: const Key('studio_filter_apply'),
                    label: 'Apply',
                    onTap: () => Navigator.of(context).pop(_query),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
