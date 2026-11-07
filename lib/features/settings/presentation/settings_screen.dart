import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';
import 'package:tiktok_mobile/features/settings/presentation/widgets/settings_widgets.dart';

/// Settings and privacy — the web's Privacy, Screen time and Content
/// preferences sections, in that order. "Download your data" and "Muted
/// accounts" are web-only.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final settings = state.valueOrNull;
    final loading = settings == null;

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Settings and privacy'),
      body: state.hasError && settings == null
          ? ErrorView(
              message: settingsErrorMessage(state.error!),
              onRetry: () => ref.invalidate(accountSettingsProvider),
            )
          : ListView(
              key: const Key('settings_list'),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              children: [
                const SettingsGroupTitle('Privacy'),
                SettingsSection(
                  heading: 'Discoverability',
                  children: [
                    _SwitchRow(
                      switchKey: const Key('settings_private_account'),
                      title: 'Private account',
                      description:
                          'With a private account, only users you approve can '
                          'follow you and watch your videos. Your existing '
                          "followers won't be affected.",
                      value: settings?.privateAccount,
                      field: 'privateAccount',
                    ),
                    SettingsRow(
                      key: const Key('settings_follow_requests'),
                      title: 'Follow requests',
                      description: 'People waiting for your approval',
                      onTap: () => context.push('/me/follow-requests'),
                    ),
                  ],
                ),
                SettingsSection(
                  heading: 'Interactions',
                  children: [
                    SettingsRow(
                      key: const Key('settings_comment_audience'),
                      title: 'Comments',
                      description: 'Who can comment on your posts',
                      value: settings == null
                          ? null
                          : audienceLabel(settings.commentAudience),
                      loading: loading,
                      onTap: () => _pickAudience(
                        context,
                        title: 'Comments',
                        description: 'Who can comment on your posts',
                        field: 'commentAudience',
                        current: settings!.commentAudience,
                      ),
                    ),
                    SettingsRow(
                      key: const Key('settings_comment_filters'),
                      title: 'Comment filters',
                      description:
                          'Hold comments for your review before they appear',
                      onTap: () => context.push('/me/comment-filters'),
                    ),
                    SettingsRow(
                      key: const Key('settings_dm_audience'),
                      title: 'Direct messages',
                      description: 'Who can send you messages',
                      loading: loading,
                      onTap: () => _pickAudience(
                        context,
                        title: 'Direct messages',
                        description: 'Who can send you messages',
                        field: 'dmAudience',
                        current: settings!.dmAudience,
                      ),
                    ),
                    SettingsRow(
                      key: const Key('settings_blocked_accounts'),
                      title: 'Blocked accounts',
                      onTap: () => context.push('/me/blocked'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const SettingsGroupTitle('Screen time'),
                SettingsSection(
                  children: [
                    SettingsRow(
                      key: const Key('settings_daily_screen_time'),
                      title: 'Daily screen time',
                      description:
                          'Get notified if you reach your time on Nowa.',
                      value: settings == null ? null : _todayLimit(settings),
                      loading: loading,
                      onTap: () => context.push('/settings/screen-time/daily'),
                    ),
                    SettingsRow(
                      key: const Key('settings_sleep_hours'),
                      title: 'Sleep hours',
                      description:
                          "Get reminded when you're in your sleep hours.",
                      value: settings?.sleepHoursStart == null ? 'Off' : 'On',
                      loading: loading,
                      onTap: () => context.push('/settings/screen-time/sleep'),
                    ),
                    _SwitchRow(
                      switchKey: const Key('settings_weekly_screen_time'),
                      title: 'Weekly screen time updates',
                      description: 'Stay updated on your time from your Inbox.',
                      value: settings?.weeklyScreenTimeDigest,
                      field: 'weeklyScreenTimeDigest',
                    ),
                    SettingsRow(
                      key: const Key('settings_screen_time_summary'),
                      title: 'Summary',
                      description:
                          'Your weekly metrics include your time on the app '
                          'and on nowa.com.',
                      onTap: () =>
                          context.push('/settings/screen-time/summary'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const SettingsGroupTitle('Content preferences'),
                SettingsSection(
                  children: [
                    SettingsRow(
                      key: const Key('settings_keyword_filters'),
                      title: 'Filter keywords',
                      description:
                          "When you filter a keyword, you won't see posts in "
                          'your selected feeds that contain that word in any '
                          'titles, descriptions, or stickers. Certain keywords '
                          "can't be filtered.",
                      onTap: () => context.push('/settings/keyword-filters'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  static String _todayLimit(UserSettings settings) {
    final limit = settings.limitFor(DateTime.now().weekday);
    return limit == null ? 'Off' : formatLimit(limit);
  }

  Future<void> _pickAudience(
    BuildContext context, {
    required String title,
    required String description,
    required String field,
    required SettingsAudience current,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AudienceSheet(
        title: title,
        description: description,
        field: field,
        current: current,
      ),
    );
  }
}

String audienceLabel(SettingsAudience audience) => switch (audience) {
  SettingsAudience.friends => 'Friends',
  SettingsAudience.noOne => 'No one',
  _ => 'Everyone',
};

/// A switch saved straight away: it shows the new value while the PATCH is
/// in flight, ignores taps meanwhile, and goes back if the server refuses.
class _SwitchRow extends ConsumerStatefulWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.title,
    required this.description,
    required this.value,
    required this.field,
  });

  final Key switchKey;
  final String title;
  final String description;

  /// Null until settings have loaded — the switch is disabled until then.
  final bool? value;
  final String field;

  @override
  ConsumerState<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends ConsumerState<_SwitchRow> {
  bool? _pending;

  Future<void> _toggle(bool next) async {
    if (_pending != null) return;
    setState(() => _pending = next);
    try {
      await ref.read(accountSettingsProvider.notifier).save({
        widget.field: next,
      });
    } catch (e) {
      if (mounted) showSettingsMessage(context, settingsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSwitchRow(
      switchKey: widget.switchKey,
      title: widget.title,
      description: widget.description,
      value: _pending ?? widget.value ?? false,
      onChanged: widget.value == null ? null : _toggle,
    );
  }
}

/// Everyone / Friends / No one. Picking another saves it; the sheet closes
/// on success and stays, with the old choice, on failure.
class _AudienceSheet extends ConsumerStatefulWidget {
  const _AudienceSheet({
    required this.title,
    required this.description,
    required this.field,
    required this.current,
  });

  final String title;
  final String description;
  final String field;
  final SettingsAudience current;

  @override
  ConsumerState<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends ConsumerState<_AudienceSheet> {
  SettingsAudience? _saving;
  String? _error;

  static const _options = [
    (SettingsAudience.everyone, 'Everyone', null),
    (SettingsAudience.friends, 'Friends', 'Followers that you follow back'),
    (SettingsAudience.noOne, 'No one', null),
  ];

  Future<void> _choose(SettingsAudience value) async {
    if (_saving != null) return;
    if (value == widget.current) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = value;
      _error = null;
    });
    try {
      await ref.read(accountSettingsProvider.notifier).save({
        widget.field: value.wire,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = null;
          _error = settingsErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _saving ?? widget.current;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: sora(size: 16)),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: work(size: 12.5, color: NowaColors.dim),
            ),
            const SizedBox(height: 10),
            for (final (value, label, sub) in _options)
              ListTile(
                key: Key('audience_${value.wire.toLowerCase()}'),
                contentPadding: EdgeInsets.zero,
                enabled: _saving == null,
                onTap: () => _choose(value),
                title: Text(label, style: work(size: 14.5)),
                subtitle: sub == null
                    ? null
                    : Text(sub, style: work(size: 12, color: NowaColors.dim)),
                trailing: Icon(
                  selected == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected == value
                      ? NowaColors.accent
                      : NowaColors.text.withValues(alpha: 0.4),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: work(size: 12.5, color: NowaColors.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
