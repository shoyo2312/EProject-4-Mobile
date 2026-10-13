import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// What the poster filled in. `null` back from [showPostSheet] means they
/// backed out.
class PostDetails {
  const PostDetails({
    required this.title,
    required this.description,
    required this.visibility,
    required this.tags,
  });

  final String title;
  final String? description;
  final VideoVisibility visibility;
  final List<String> tags;
}

Future<PostDetails?> showPostSheet(BuildContext context, {required File file}) {
  return showModalBottomSheet<PostDetails>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PostSheet(file: file),
  );
}

class _PostSheet extends StatefulWidget {
  const _PostSheet({required this.file});

  final File file;

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  var _visibility = VideoVisibility.public;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  /// Splits on commas and spaces and drops the empties. The server lowercases,
  /// trims, strips a leading `#` and de-duplicates anyway (video doc 3.2), so
  /// nothing more is done here — normalising twice would only disagree.
  List<String> get _tagList => _tags.text
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .take(10)
      .toList();

  @override
  Widget build(BuildContext context) {
    final title = _title.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: NowaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: NowaColors.hairline)),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          14,
          18,
          MediaQuery.of(context).viewPadding.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: NowaColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('New post', style: sora(size: 16)),
            const SizedBox(height: 4),
            Text(
              widget.file.uri.pathSegments.last,
              style: work(size: 11, color: NowaColors.dim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            _Field(
              key: const Key('post_title_field'),
              controller: _title,
              hint: 'Title',
              maxLength: 150,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _Field(
              key: const Key('post_description_field'),
              controller: _description,
              hint: 'Description (optional)',
              maxLength: 2000,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _Field(
              key: const Key('post_tags_field'),
              controller: _tags,
              hint: 'Tags, separated by spaces (max 10)',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final v in [VideoVisibility.public, VideoVisibility.private])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _visibility = v),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: v == _visibility
                              ? NowaColors.accent.withValues(alpha: 0.9)
                              : NowaColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          v == VideoVisibility.public ? 'Public' : 'Private',
                          style: sora(size: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            NowaButton(
              key: const Key('post_submit_button'),
              label: 'Post',
              // A title of only whitespace is a 400 from the server, so the
              // button stays off until there is one.
              onTap: title.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                        PostDetails(
                          title: title,
                          description: _description.text.trim().isEmpty
                              ? null
                              : _description.text.trim(),
                          visibility: _visibility,
                          tags: _tagList,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      style: work(size: 13),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: work(size: 13, color: NowaColors.dim),
        filled: true,
        fillColor: NowaColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
