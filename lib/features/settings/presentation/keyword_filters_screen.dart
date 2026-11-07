import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';
import 'package:tiktok_mobile/features/settings/presentation/widgets/settings_widgets.dart';

const _lead =
    "When you filter a keyword, you won't see posts in your selected feeds "
    'that contain that word in any titles, descriptions, or stickers.';

/// Content preferences → Filter keywords: the list, and in place of it the
/// add / edit form. Back from the form returns to the list.
class KeywordFiltersScreen extends ConsumerStatefulWidget {
  const KeywordFiltersScreen({super.key});

  @override
  ConsumerState<KeywordFiltersScreen> createState() =>
      _KeywordFiltersScreenState();
}

class _KeywordFiltersScreenState extends ConsumerState<KeywordFiltersScreen> {
  /// Open form: `(filter: null)` adds, `(filter: f)` edits [f].
  ({KeywordFilter? filter})? _form;
  final _deleting = <String>{};

  Future<void> _delete(KeywordFilter filter) async {
    setState(() => _deleting.add(filter.id));
    try {
      await ref.read(keywordFiltersProvider.notifier).delete(filter.id);
    } catch (e) {
      if (mounted) showSettingsMessage(context, settingsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _deleting.remove(filter.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(keywordFiltersProvider);
    final form = _form;
    return PopScope(
      canPop: form == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _form = null);
      },
      child: Scaffold(
        backgroundColor: NowaColors.bg,
        appBar: NowaAppBar(
          title: form == null
              ? 'Filter keywords'
              : form.filter == null
              ? 'Add keyword'
              : 'Edit keyword',
        ),
        body: form != null
            ? _KeywordForm(
                key: ValueKey(form.filter?.id ?? 'new'),
                editing: form.filter,
                others: [
                  for (final f
                      in filters.valueOrNull ?? const <KeywordFilter>[])
                    if (f.id != form.filter?.id) f.keyword,
                ],
                onSaved: () => setState(() => _form = null),
              )
            : filters.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: settingsErrorMessage(error),
                  onRetry: () => ref.invalidate(keywordFiltersProvider),
                ),
                data: (list) => _list(list),
              ),
      ),
    );
  }

  Widget _list(List<KeywordFilter> list) {
    return ListView.builder(
      key: const Key('keyword_filters_list'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsLead(_lead),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 200,
                    child: NowaButton(
                      key: const Key('keyword_filters_add'),
                      label: 'Add keyword',
                      icon: Icons.add,
                      onTap: () => setState(() => _form = (filter: null)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final filter = list[index - 1];
        final busy = _deleting.contains(filter.id);
        return Container(
          key: Key('keyword_filter_${filter.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                    Text(filter.keyword, style: work(size: 14.5)),
                    const SizedBox(height: 3),
                    Text(
                      feedsLabel(filter),
                      style: work(size: 12, color: NowaColors.dim),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: Key('keyword_filter_edit_${filter.id}'),
                onPressed: busy
                    ? null
                    : () => setState(() => _form = (filter: filter)),
                child: Text('Edit', style: work(size: 13)),
              ),
              TextButton(
                key: Key('keyword_filter_delete_${filter.id}'),
                onPressed: busy ? null : () => _delete(filter),
                child: Text(
                  'Delete',
                  style: work(size: 13, color: NowaColors.danger),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "For You, Friends" — always in this order.
String feedsLabel(KeywordFilter f) => [
  if (f.forYou) 'For You',
  if (f.following) 'Following',
  if (f.friends) 'Friends',
].join(', ');

class _KeywordForm extends ConsumerStatefulWidget {
  const _KeywordForm({
    super.key,
    required this.editing,
    required this.others,
    required this.onSaved,
  });

  final KeywordFilter? editing;

  /// Every other keyword on the account, for the duplicate check.
  final List<String> others;
  final VoidCallback onSaved;

  @override
  ConsumerState<_KeywordForm> createState() => _KeywordFormState();
}

class _KeywordFormState extends ConsumerState<_KeywordForm> {
  late final _controller = TextEditingController(
    text: widget.editing?.keyword ?? '',
  );

  // A new keyword starts with no feed ticked: choosing is part of adding.
  late bool _forYou = widget.editing?.forYou ?? false;
  late bool _following = widget.editing?.following ?? false;
  late bool _friends = widget.editing?.friends ?? false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(keywordFiltersProvider.notifier)
          .save(
            editing: widget.editing,
            keyword: normalizeKeyword(_controller.text),
            forYou: _forYou,
            following: _following,
            friends: _friends,
          );
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) showSettingsMessage(context, settingsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final trimmed = text.trim();
    final error = keywordError(text, widget.others);
    final anyFeed = _forYou || _following || _friends;
    final canSave = trimmed.isNotEmpty && error == null && anyFeed && !_saving;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      children: [
        const SettingsLead(
          'Enter a word, hashtag or phrase to filter from selected feeds. '
          "Spelling isn't case-sensitive.",
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('keyword_form_field'),
          controller: _controller,
          autofocus: widget.editing == null,
          autocorrect: false,
          cursorColor: NowaColors.accent,
          style: work(size: 14.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: NowaColors.surfaceHigh,
            hintText: 'Enter a word, hashtag or phrase',
            hintStyle: work(
              size: 14.5,
              color: NowaColors.text.withValues(alpha: 0.3),
            ),
            suffixIcon: text.isEmpty
                ? null
                : IconButton(
                    key: const Key('keyword_form_clear'),
                    icon: const Icon(Icons.cancel, size: 18),
                    color: NowaColors.dim,
                    onPressed: _controller.clear,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: error == null
                  ? const SizedBox.shrink()
                  : Text(
                      error,
                      key: const Key('keyword_form_error'),
                      style: work(size: 12.5, color: NowaColors.danger),
                    ),
            ),
            Text(
              '${text.runes.length}/200',
              style: work(size: 11.5, color: NowaColors.dim),
            ),
          ],
        ),
        if (trimmed.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Filter from', style: sora(size: 14)),
              const Spacer(),
              TextButton(
                key: const Key('keyword_form_select_all'),
                onPressed: () => setState(() {
                  _forYou = true;
                  _following = true;
                  _friends = true;
                }),
                child: Text(
                  'Select all',
                  style: work(size: 13, color: NowaColors.accent),
                ),
              ),
            ],
          ),
          _FeedBox(
            boxKey: const Key('keyword_form_for_you'),
            label: 'For You',
            value: _forYou,
            onChanged: (v) => setState(() => _forYou = v),
          ),
          _FeedBox(
            boxKey: const Key('keyword_form_following'),
            label: 'Following',
            value: _following,
            onChanged: (v) => setState(() => _following = v),
          ),
          _FeedBox(
            boxKey: const Key('keyword_form_friends'),
            label: 'Friends',
            value: _friends,
            onChanged: (v) => setState(() => _friends = v),
          ),
        ],
        const SizedBox(height: 24),
        NowaButton(
          key: const Key('keyword_form_save'),
          label: 'Save',
          height: 50,
          loading: _saving,
          onTap: canSave ? _save : null,
        ),
      ],
    );
  }
}

class _FeedBox extends StatelessWidget {
  const _FeedBox({
    required this.boxKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key boxKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: boxKey,
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: NowaColors.accent,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(label, style: work(size: 14)),
    );
  }
}
