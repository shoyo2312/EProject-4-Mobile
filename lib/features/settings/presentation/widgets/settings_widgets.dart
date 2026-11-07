import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// A titled block of rows on a dark card.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.heading, required this.children});

  final String? heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SectionLabel(heading!.toUpperCase()),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: NowaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NowaColors.hairline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      color: NowaColors.hairline,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A big screen title with its group of sections under it.
class SettingsGroupTitle extends StatelessWidget {
  const SettingsGroupTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
    child: Text(text, style: sora(size: 18, spacing: -0.3)),
  );
}

/// A tappable row: title, optional description, and a value and/or chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.description,
    this.value,
    this.onTap,
    this.loading = false,
  });

  final String title;
  final String? description;

  /// Shown before the chevron; a link row leaves it out.
  final String? value;
  final VoidCallback? onTap;

  /// Settings not read yet: a dim placeholder instead of the value, and the
  /// row does not open.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _RowText(title: title, description: description),
            ),
            const SizedBox(width: 12),
            if (loading)
              Container(
                width: 34,
                height: 12,
                decoration: BoxDecoration(
                  color: NowaColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
              )
            else if (value != null)
              Text(
                value!,
                style: work(
                  size: 13,
                  color: NowaColors.text.withValues(alpha: 0.55),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: NowaColors.text.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row with a switch. [onChanged] null disables it.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.switchKey,
    required this.title,
    this.description,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: _RowText(title: title, description: description),
          ),
          const SizedBox(width: 8),
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

class _RowText extends StatelessWidget {
  const _RowText({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: work(size: 14.5, height: 1.3)),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description!,
            style: work(
              size: 12,
              height: 1.4,
              color: NowaColors.text.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small print under a page title.
class SettingsLead extends StatelessWidget {
  const SettingsLead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: work(
      size: 13,
      height: 1.5,
      color: NowaColors.text.withValues(alpha: 0.6),
    ),
  );
}

/// Four digit boxes over one hidden field. [onCompleted] fires when the
/// fourth digit is typed; the parent clears it through [controller].
class PasscodeField extends StatefulWidget {
  const PasscodeField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.error = false,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool error;
  final bool enabled;
  final bool autofocus;

  @override
  State<PasscodeField> createState() => _PasscodeFieldState();
}

class _PasscodeFieldState extends State<PasscodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PasscodeField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    // Re-enabled after a check: the boxes were cleared, so type again.
    if (!old.enabled && widget.enabled) _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == 4) widget.onCompleted(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kept in the tree, invisible, so the keyboard and paste work.
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                key: const Key('passcode_input'),
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: false,
                enableInteractiveSelection: false,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                // 4 × 48 + 3 × 10 = 222: fits a dialog on a 360-wide phone.
                Container(
                  width: 48,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NowaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.error
                          ? NowaColors.danger
                          : i == text.length && widget.enabled
                          ? NowaColors.accent
                          : NowaColors.hairline,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    i < text.length ? '•' : '',
                    style: sora(size: 26),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A pill chip that can be selected.
class SettingsChip extends StatelessWidget {
  const SettingsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? NowaColors.accent.withValues(alpha: 0.18)
              : NowaColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NowaColors.accent : NowaColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: work(
            size: 13,
            color: selected ? NowaColors.accent : NowaColors.text,
          ),
        ),
      ),
    );
  }
}

/// A SnackBar with [message], from anywhere a context reaches a messenger.
void showSettingsMessage(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
