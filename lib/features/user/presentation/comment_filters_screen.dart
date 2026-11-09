import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/user/data/comment_filter_settings.dart';
import 'package:tiktok_mobile/features/user/presentation/comment_filters_provider.dart';

/// Which comments on the signed-in account's videos get held back. A held
/// comment is shown to nobody but its author.
class CommentFiltersScreen extends ConsumerStatefulWidget {
  const CommentFiltersScreen({super.key});

  @override
  ConsumerState<CommentFiltersScreen> createState() =>
      _CommentFiltersScreenState();
}

class _CommentFiltersScreenState extends ConsumerState<CommentFiltersScreen> {
  final _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// Every change is saved straight away; a refusal puts the old value back
  /// (see [CommentFilters]) and says why.
  Future<void> _run(
    Future<void> Function(CommentFilters notifier) action,
  ) async {
    final toast = NowaToast.of(context);
    try {
      await action(ref.read(commentFiltersProvider.notifier));
    } on AppException catch (e) {
      toast.error(e.message);
    }
  }

  void _addKeyword(CommentFilterSettings settings) {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;
    final problem = _keywordProblem(keyword, settings.commentKeywords);
    if (problem != null) {
      NowaToast.of(context).error(problem);
      return;
    }
    _keywordController.clear();
    _run((n) => n.setKeywords([...settings.commentKeywords, keyword]));
  }

  /// The server's own limits, checked first so the common mistakes get a
  /// clear message instead of a VALIDATION_ERROR.
  static String? _keywordProblem(String keyword, List<String> existing) {
    if (keyword.runes.length > CommentFilterSettings.maxKeywordLength) {
      return 'Keywords can be up to '
          '${CommentFilterSettings.maxKeywordLength} characters';
    }
    if (existing.length >= CommentFilterSettings.maxKeywords) {
      return 'You can add up to ${CommentFilterSettings.maxKeywords} keywords';
    }
    final lower = keyword.toLowerCase();
    if (existing.any((k) => k.toLowerCase() == lower)) {
      return '"$keyword" is already on your list';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(commentFiltersProvider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Comment filters'),
      body: filters.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(commentFiltersProvider),
        ),
        data: (settings) => ListView(
          key: const Key('comment_filters_list'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            Text(
              'Applies to comments other people leave on your videos. '
              'Filtered comments are only visible to the person who wrote them.',
              style: work(
                size: 12.5,
                height: 1.4,
                color: NowaColors.text.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 18),
            _SwitchTile(
              switchKey: const Key('comment_filters_spam_switch'),
              title: 'Filter spam and offensive comments',
              subtitle: 'Hide comments flagged as spam, rude or offensive.',
              value: settings.filterSpamOffensive,
              onChanged: (v) => _run((n) => n.setFilterSpamOffensive(v)),
            ),
            const SizedBox(height: 10),
            _SwitchTile(
              switchKey: const Key('comment_filters_all_switch'),
              title: 'Filter all comments',
              subtitle: 'Hide every new comment from other people.',
              value: settings.filterAllComments,
              onChanged: (v) => _run((n) => n.setFilterAllComments(v)),
            ),
            const SizedBox(height: 26),
            const SectionLabel('FILTER KEYWORDS'),
            const SizedBox(height: 6),
            Text(
              'Hide comments that contain these words. '
              '${settings.commentKeywords.length}/'
              '${CommentFilterSettings.maxKeywords}',
              style: work(
                size: 12.5,
                color: NowaColors.text.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: NowaColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: TextField(
                        key: const Key('comment_filters_keyword_field'),
                        controller: _keywordController,
                        onSubmitted: (_) => _addKeyword(settings),
                        cursorColor: NowaColors.accent,
                        style: work(size: 13.5, height: 1.2),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Add a keyword',
                          hintStyle: work(
                            size: 13.5,
                            height: 1.2,
                            color: NowaColors.text.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 72,
                  child: NowaButton(
                    key: const Key('comment_filters_add_keyword'),
                    label: 'Add',
                    height: 46,
                    onTap: () => _addKeyword(settings),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final keyword in settings.commentKeywords)
                  _KeywordChip(
                    keyword: keyword,
                    onRemove: () => _run(
                      (n) => n.setKeywords([
                        for (final k in settings.commentKeywords)
                          if (k != keyword) k,
                      ]),
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.switchKey,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NowaColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: sora(size: 13.5)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: work(
                    size: 12,
                    height: 1.35,
                    color: NowaColors.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: switchKey,
            value: value,
            onChanged: onChanged,
            activeTrackColor: NowaColors.accent,
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.keyword, required this.onRemove});

  final String keyword;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
      decoration: BoxDecoration(
        color: NowaColors.surfaceHigh,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: NowaColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(keyword, style: work(size: 12.5, height: 1)),
          const SizedBox(width: 4),
          GestureDetector(
            key: Key('comment_filters_remove_$keyword'),
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: NowaColors.text.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
