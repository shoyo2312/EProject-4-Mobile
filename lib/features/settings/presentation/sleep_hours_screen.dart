import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';
import 'package:tiktok_mobile/features/settings/presentation/widgets/settings_widgets.dart';

/// Screen time → Sleep hours. Only the start is chosen: sleep hours always
/// last eight hours, and the server works out the end.
class SleepHoursSettingsScreen extends ConsumerWidget {
  const SleepHoursSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accountSettingsProvider).valueOrNull;
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Sleep hours'),
      body: settings == null
          ? const LoadingView()
          : _SleepHoursForm(start: settings.sleepHoursStart),
    );
  }
}

class _SleepHoursForm extends ConsumerStatefulWidget {
  const _SleepHoursForm({required this.start});

  final String? start;

  @override
  ConsumerState<_SleepHoursForm> createState() => _SleepHoursFormState();
}

class _SleepHoursFormState extends ConsumerState<_SleepHoursForm> {
  late bool _on = widget.start != null;
  late String _start = widget.start ?? '22:00';
  bool _saving = false;

  Future<void> _pickStart() async {
    final parts = _start.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: NowaColors.accent,
            surface: NowaColors.surfaceHigh,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() => _start = '${two(picked.hour)}:${two(picked.minute)}');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(accountSettingsProvider.notifier).save({
        'sleepHoursStart': _on ? _start : null,
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSettingsMessage(context, settingsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      children: [
        const SettingsLead(
          'To help you sleep, push notifications are muted during your sleep '
          "hours. We'll remind you before and after they start.",
        ),
        const SizedBox(height: 20),
        SettingsSection(
          children: [
            SettingsSwitchRow(
              switchKey: const Key('sleep_hours_switch'),
              title: 'Set your sleep hours',
              value: _on,
              onChanged: _saving ? null : (v) => setState(() => _on = v),
            ),
            Opacity(
              opacity: _on ? 1 : 0.4,
              child: SettingsRow(
                key: const Key('sleep_hours_start'),
                title: 'Start time',
                value: formatClockTime(_start),
                onTap: _on && !_saving ? _pickStart : null,
              ),
            ),
            Opacity(
              opacity: 0.4,
              child: SettingsRow(
                key: const Key('sleep_hours_end'),
                title: 'End time',
                value: formatClockTime(addHours(_start, 8)),
              ),
            ),
          ],
        ),
        Text(
          'Sleep hours last for 8 hours after your start time',
          style: work(size: 12, color: NowaColors.dim),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: NowaButton(
                key: const Key('sleep_hours_cancel'),
                label: 'Cancel',
                filled: false,
                onTap: _saving ? null : () => context.pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NowaButton(
                key: const Key('sleep_hours_save'),
                label: 'Save',
                loading: _saving,
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
