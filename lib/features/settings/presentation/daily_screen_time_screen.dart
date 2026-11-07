import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';
import 'package:tiktok_mobile/features/settings/presentation/widgets/settings_widgets.dart';

/// Screen time → Daily screen time. Nothing is saved until Done; turning the
/// limit on for the first time asks for a passcode, which is the only way
/// past the limit once it is reached.
class DailyScreenTimeScreen extends ConsumerWidget {
  const DailyScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accountSettingsProvider).valueOrNull;
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Daily screen time'),
      body: settings == null
          ? const LoadingView()
          : _DailyLimitForm(original: settings),
    );
  }
}

const _presets = [40, 60, 90, 120];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _DailyLimitForm extends ConsumerStatefulWidget {
  const _DailyLimitForm({required this.original});

  final UserSettings original;

  @override
  ConsumerState<_DailyLimitForm> createState() => _DailyLimitFormState();
}

class _DailyLimitFormState extends ConsumerState<_DailyLimitForm> {
  late bool _on = widget.original.dailyLimitOn;
  late bool _perDay = widget.original.screenTimeLimitsByDay != null;

  /// A preset in minutes, -1 for "Custom", or null when nothing is picked
  /// yet (Done stays off).
  late int? _choice = _initialChoice();
  late int _custom = _isCustom ? widget.original.screenTimeLimitMinutes! : 60;
  late final List<int> _days =
      widget.original.screenTimeLimitsByDay?.length == 7
      ? [...widget.original.screenTimeLimitsByDay!]
      : List.filled(7, 60);
  int _editingDay = DateTime.now().weekday - 1;
  bool _saving = false;

  bool get _isCustom {
    final minutes = widget.original.screenTimeLimitMinutes;
    return minutes != null && !_presets.contains(minutes);
  }

  int? _initialChoice() {
    final minutes = widget.original.screenTimeLimitMinutes;
    if (minutes == null) return null;
    return _presets.contains(minutes) ? minutes : -1;
  }

  /// Both shapes always go in the body, the unused one as null.
  Map<String, dynamic>? get _patch {
    if (!_on) {
      return {'screenTimeLimitMinutes': null, 'screenTimeLimitsByDay': null};
    }
    if (_perDay) {
      return {'screenTimeLimitMinutes': null, 'screenTimeLimitsByDay': _days};
    }
    if (_choice == null) return null;
    return {
      'screenTimeLimitMinutes': _choice == -1 ? _custom : _choice,
      'screenTimeLimitsByDay': null,
    };
  }

  Future<void> _done() async {
    final patch = _patch;
    if (patch == null || _saving) return;
    var body = patch;
    if (_on && !widget.original.hasScreenTimePasscode) {
      final passcode = await showDialog<String>(
        context: context,
        builder: (_) => const _CreatePasscodeDialog(),
      );
      if (passcode == null || !mounted) return;
      body = {...patch, 'screenTimePasscode': passcode};
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountSettingsProvider.notifier).save(body);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSettingsMessage(context, settingsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDuration(int initial, ValueChanged<int> onPicked) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DurationPicker(initialMinutes: initial),
    );
    if (picked != null && mounted) setState(() => onPicked(picked));
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _patch != null && !_saving;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      children: [
        const SettingsLead(
          "We'll let you know if you reach your daily time to help you "
          'balance your day.',
        ),
        const SizedBox(height: 18),
        const _Info(
          icon: Icons.timer_outlined,
          title: 'Set your daily time',
          text: 'Choose how long to spend on Nowa',
        ),
        const SizedBox(height: 12),
        const _Info(
          icon: Icons.notifications_none,
          title: 'Get notified',
          text:
              'Close Nowa to stay within your daily time, or enter a '
              'passcode to return to it',
        ),
        const SizedBox(height: 20),
        SettingsSection(
          children: [
            SettingsSwitchRow(
              switchKey: const Key('daily_limit_switch'),
              title: 'Set daily screen time',
              value: _on,
              onChanged: _saving ? null : (v) => setState(() => _on = v),
            ),
            if (_on) ...[
              _RadioRow(
                rowKey: const Key('daily_limit_same'),
                label: 'Set the same limit every day',
                selected: !_perDay,
                onTap: () => setState(() => _perDay = false),
              ),
              _RadioRow(
                rowKey: const Key('daily_limit_per_day'),
                label: 'Set a custom limit per day',
                selected: _perDay,
                onTap: () => setState(() => _perDay = true),
              ),
            ],
          ],
        ),
        if (_on && !_perDay)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in _presets)
                SettingsChip(
                  key: Key('daily_limit_preset_$minutes'),
                  label: formatLimit(minutes),
                  selected: _choice == minutes,
                  onTap: () => setState(() => _choice = minutes),
                ),
              SettingsChip(
                key: const Key('daily_limit_custom'),
                label: _choice == -1
                    ? 'Custom · ${formatLimit(_custom)}'
                    : 'Custom',
                selected: _choice == -1,
                onTap: () => _pickDuration(_custom, (m) {
                  _custom = m;
                  _choice = -1;
                }),
              ),
            ],
          ),
        if (_on && _perDay) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                SettingsChip(
                  label: _weekdays[i],
                  selected: _editingDay == i,
                  onTap: () => setState(() => _editingDay = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsSection(
            children: [
              for (var i = 0; i < 7; i++)
                SettingsRow(
                  key: Key('daily_limit_day_$i'),
                  title: _weekdays[i],
                  value: formatLimit(_days[i]),
                  onTap: () {
                    setState(() => _editingDay = i);
                    _pickDuration(_days[i], (m) => _days[i] = m);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        NowaButton(
          key: const Key('daily_limit_done'),
          label: 'Done',
          height: 50,
          loading: _saving,
          onTap: canSave ? _done : null,
        ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.rowKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key rowKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: rowKey,
      onTap: onTap,
      title: Text(label, style: work(size: 14)),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? NowaColors.accent
            : NowaColors.text.withValues(alpha: 0.4),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: NowaColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: work(size: 14)),
              const SizedBox(height: 2),
              Text(
                text,
                style: work(size: 12.5, height: 1.4, color: NowaColors.dim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hours 0–8 and minutes in fives, kept to the server's 10–480.
class _DurationPicker extends StatefulWidget {
  const _DurationPicker({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _hours = widget.initialMinutes ~/ 60;
  late int _minutes = (widget.initialMinutes % 60) ~/ 5 * 5;

  int get _total => (_hours * 60 + _minutes).clamp(10, 480);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Custom limit', style: sora(size: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: _Wheel(
                      count: 9,
                      initial: _hours,
                      label: (i) => '$i h',
                      onChanged: (i) => setState(() => _hours = i),
                    ),
                  ),
                  Expanded(
                    child: _Wheel(
                      count: 12,
                      initial: _minutes ~/ 5,
                      label: (i) => '${i * 5} m',
                      onChanged: (i) => setState(() => _minutes = i * 5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatLimit(_total),
              style: work(size: 13, color: NowaColors.dim),
            ),
            const SizedBox(height: 14),
            NowaButton(
              key: const Key('duration_picker_done'),
              label: 'Done',
              onTap: () => Navigator.of(context).pop(_total),
            ),
          ],
        ),
      ),
    );
  }
}

/// One scroll-wheel column.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.label,
    required this.onChanged,
  });

  final int count;
  final int initial;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(initialItem: initial),
      itemExtent: 40,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (_, i) => Center(child: Text(label(i), style: sora(size: 17))),
      ),
    );
  }
}

/// Create, then confirm, a four-digit passcode. Pops it, or null when closed.
class _CreatePasscodeDialog extends StatefulWidget {
  const _CreatePasscodeDialog();

  @override
  State<_CreatePasscodeDialog> createState() => _CreatePasscodeDialogState();
}

class _CreatePasscodeDialogState extends State<_CreatePasscodeDialog> {
  final _controller = TextEditingController();
  String? _first;
  bool _mismatch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCompleted(String code) {
    if (_first == null) {
      setState(() {
        _first = code;
        _mismatch = false;
      });
      _controller.clear();
      return;
    }
    if (code == _first) {
      Navigator.of(context).pop(code);
      return;
    }
    setState(() {
      _first = null;
      _mismatch = true;
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final confirming = _first != null;
    return Dialog(
      backgroundColor: NowaColors.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    confirming ? 'Confirm passcode' : 'Create a passcode',
                    style: sora(size: 16),
                  ),
                ),
                IconButton(
                  key: const Key('passcode_dialog_close'),
                  icon: const Icon(Icons.close, size: 20),
                  color: NowaColors.text,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              confirming
                  ? 'Enter the same four digits again.'
                  : "You'll enter it to keep using Nowa after your daily time.",
              style: work(size: 13, height: 1.4, color: NowaColors.dim),
            ),
            const SizedBox(height: 20),
            PasscodeField(
              controller: _controller,
              error: _mismatch,
              onCompleted: _onCompleted,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 18,
              child: _mismatch
                  ? Text(
                      "Passcodes don't match",
                      style: work(size: 12.5, color: NowaColors.danger),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
