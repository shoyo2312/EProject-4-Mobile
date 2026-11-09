import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_posts_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// The server's limits, counted in code points as it counts them.
const titleLimit = 150;
const descriptionLimit = 2000;

/// Studio's edit page: caption, who can watch, and whether comments are on.
class StudioEditPostScreen extends ConsumerWidget {
  const StudioEditPostScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(studioVideoProvider(videoId));
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Edit post'),
      body: video.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e is AppException ? studioErrorText(e) : e.toString(),
          onRetry: () => ref.invalidate(studioVideoProvider(videoId)),
        ),
        data: (v) => _EditForm(video: v),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.video});

  final VideoModel video;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _title = TextEditingController(text: widget.video.title);
  late final _description =
      TextEditingController(text: widget.video.description ?? '');
  late VideoVisibility _visibility = widget.video.visibility;
  late bool _commentsOff = widget.video.commentsDisabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_changed);
    _description.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _captionChanged =>
      _title.text.trim() != widget.video.title ||
      _description.text.trim() != (widget.video.description ?? '');

  bool get _dirty =>
      _captionChanged ||
      _visibility != widget.video.visibility ||
      _commentsOff != widget.video.commentsDisabled;

  String? get _problem {
    final title = _title.text.trim();
    if (title.isEmpty) return 'Add a title.';
    if (codePointLength(title) > titleLimit) {
      return 'The title can be at most $titleLimit characters.';
    }
    if (codePointLength(_description.text.trim()) > descriptionLimit) {
      return 'The description can be at most $descriptionLimit characters.';
    }
    return null;
  }

  /// Each setting is its own call; a failure stops at that one and says so,
  /// leaving what already went through saved.
  Future<void> _save() async {
    final toast = NowaToast.of(context);
    final editor = ref.read(studioEditorProvider);
    final id = widget.video.id;
    setState(() => _saving = true);
    try {
      if (_captionChanged) {
        await editor.updateCaption(
          id,
          title: _title.text.trim(),
          description: _description.text.trim(),
        );
      }
      if (_visibility != widget.video.visibility) {
        await editor.setVisibility(id, _visibility);
      }
      if (_commentsOff != widget.video.commentsDisabled) {
        await editor.setCommentsDisabled(id, _commentsOff);
      }
      ref.invalidate(studioVideoProvider(id));
      toast.success('Changes saved');
      if (mounted) context.pop();
    } on AppException catch (e) {
      toast.error(studioErrorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    final titleCount = codePointLength(_title.text.trim());
    final descCount = codePointLength(_description.text.trim());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioThumb(url: widget.video.thumbnailUrl, width: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Posted ${dateLabel(widget.video.createdAt)}',
                      style: work(size: 12.5, color: NowaColors.dim)),
                  if (statusLabel(widget.video.status) case final status?) ...[
                    const SizedBox(height: 6),
                    StudioBadge(status, color: NowaColors.danger),
                    const SizedBox(height: 4),
                    Text(statusNote(widget.video.status),
                        style: work(size: 12, color: NowaColors.dim)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Field(
          fieldKey: const Key('studio_edit_title'),
          label: 'Title',
          controller: _title,
          count: titleCount,
          limit: titleLimit,
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        _Field(
          fieldKey: const Key('studio_edit_description'),
          label: 'Description',
          controller: _description,
          count: descCount,
          limit: descriptionLimit,
          maxLines: 6,
          hint: 'Tell viewers about your video. #hashtags work here.',
        ),
        const SizedBox(height: 20),
        const SectionLabel('WHO CAN WATCH'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final v in studioVisibilities)
              Chip2(
                key: Key('studio_edit_visibility_${v.name}'),
                label: visibilityLabel(v),
                active: _visibility == v,
                onTap: () => setState(() => _visibility = v),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          key: const Key('studio_edit_comments'),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: NowaColors.accent,
          title: Text('Allow comments', style: work(size: 14)),
          subtitle: Text(
            'Turning this off stops new comments. Existing ones stay.',
            style: work(size: 12, color: NowaColors.dim),
          ),
          value: !_commentsOff,
          onChanged: (on) => setState(() => _commentsOff = !on),
        ),
        const SizedBox(height: 20),
        if (problem != null && _dirty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(problem, style: work(size: 12.5, color: NowaColors.danger)),
          ),
        NowaButton(
          key: const Key('studio_edit_save'),
          label: 'Save',
          loading: _saving,
          onTap: _dirty && problem == null ? _save : null,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.count,
    required this.limit,
    required this.maxLines,
    this.hint,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int count;
  final int limit;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(label.toUpperCase())),
            Text(
              '$count/$limit',
              style: work(
                size: 11.5,
                color: count > limit ? NowaColors.danger : NowaColors.dim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          minLines: 1,
          maxLines: maxLines,
          style: work(size: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: work(size: 13.5, color: NowaColors.dim),
            filled: true,
            fillColor: NowaColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
