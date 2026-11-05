import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// One slot on the horizontal glass rail under a feed caption.
class RailAction {
  const RailAction({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
    this.onHold,
    this.holdDuration = kLongPressTimeout,
    this.showHoldProgress = false,
    this.itemKey,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Null renders the slot as a read-only counter — used for the metrics the
  /// backend reports but exposes no write endpoint for.
  final VoidCallback? onTap;

  /// A press held for [holdDuration], with where the finger is. Letting go
  /// sooner is a plain tap.
  final void Function(Offset globalPosition)? onHold;
  final Duration holdDuration;

  /// Draws a ring filling round the icon while the press is held, for a hold
  /// long enough that the finger needs to know something is coming.
  final bool showHoldProgress;
  final Key? itemKey;
}

/// Horizontal glass rail: like → comment → save → share.
class ActionRail extends StatelessWidget {
  const ActionRail({super.key, required this.actions});

  final List<RailAction> actions;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const _Divider(),
            Expanded(child: _RailItem(key: actions[i].itemKey, action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({super.key, required this.action});

  final RailAction action;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem>
    with SingleTickerProviderStateMixin {
  // The tap recognizer reports the press only after kPressTimeout, so the
  // ring runs for the rest of the hold and fills as the hold fires.
  //
  // Created in initState, not as a lazy `late final` initializer: a button
  // never pressed would otherwise build its controller for the first time in
  // dispose(), whose ticker looks up TickerMode on an already-deactivated
  // element and throws. That throw aborts Flutter's unmount pass, so every
  // widget still queued behind it is never disposed — including the profile
  // tab's subscription to myProfileProvider, which then keeps the previous
  // account's profile alive across logout/login.
  late final AnimationController _hold;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: _ringDuration);
  }

  Duration get _ringDuration {
    final rest = widget.action.holdDuration - kPressTimeout;
    return rest > Duration.zero ? rest : widget.action.holdDuration;
  }

  @override
  void didUpdateWidget(covariant _RailItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hold.duration = _ringDuration;
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _pressStarted() {
    if (widget.action.showHoldProgress && widget.action.onHold != null) {
      _hold.forward(from: 0);
    }
  }

  /// Unconditional: a tap that wins the arena only on release reports its
  /// down and its up back to back, so the ring may have just been started.
  void _pressEnded() => _hold.value = 0;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final gestures = <Type, GestureRecognizerFactory>{
      if (action.onTap != null)
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (recognizer) => recognizer
            ..onTapDown = ((_) {
              _pressStarted();
            })
            ..onTapUp = ((_) {
              _pressEnded();
            })
            ..onTapCancel = _pressEnded
            ..onTap = action.onTap,
        ),
      if (action.onHold != null)
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: action.holdDuration),
          (recognizer) => recognizer
            ..onLongPressStart = (details) {
              _pressEnded();
              action.onHold!(details.globalPosition);
            },
        ),
    };

    final icon = Icon(action.icon, size: 23, color: action.color);
    return RawGestureDetector(
      gestures: gestures,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!action.showHoldProgress)
              icon
            else
              SizedBox(
                width: 23,
                height: 23,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    icon,
                    Positioned(
                      left: -7,
                      top: -7,
                      right: -7,
                      bottom: -7,
                      child: AnimatedBuilder(
                        animation: _hold,
                        builder: (context, _) => _hold.value == 0
                            ? const SizedBox.shrink()
                            : CircularProgressIndicator(
                                key: const Key('rail_hold_progress'),
                                value: _hold.value,
                                strokeWidth: 2.2,
                                color: NowaColors.accent,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(action.label, style: sora(size: 11, color: action.color)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26,
        color: Colors.white.withValues(alpha: 0.1),
      );
}
