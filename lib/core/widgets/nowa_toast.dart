import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// What a toast tells the user; sets its icon and tint.
enum ToastKind { success, error, info }

/// The app's in-app message: a glass card that drops in under the status bar,
/// clear of the nav bar and the feed's action row, and leaves on its own or
/// when swiped up. One at a time: a new one replaces the last.
///
/// Like `ScaffoldMessenger.of`, hold it before an `await` when the widget may
/// be gone by the time the message is ready:
///
/// ```dart
/// final toast = NowaToast.of(context);
/// await save();
/// toast.success('Changes saved');
/// ```
class NowaToast {
  NowaToast._(this._overlay);

  /// The outermost overlay. In the app that is the one `main.dart` wraps
  /// around the router, so a toast stays above every route, including ones
  /// pushed after it; a bare `MaterialApp` (tests) falls back to its
  /// navigator's.
  factory NowaToast.of(BuildContext context) =>
      NowaToast._(Overlay.maybeOf(context, rootOverlay: true));

  /// Wraps every toast, whatever key its caller gave it.
  static const viewKey = Key('nowa_toast');

  final OverlayState? _overlay;

  static _Shown? _current;

  void success(
    String message, {
    Key? key,
    String? actionLabel,
    VoidCallback? onAction,
    Key? actionKey,
  }) => show(
    message,
    kind: ToastKind.success,
    key: key,
    actionLabel: actionLabel,
    onAction: onAction,
    actionKey: actionKey,
  );

  void error(String message, {Key? key}) =>
      show(message, kind: ToastKind.error, key: key);

  void info(String message, {Key? key}) =>
      show(message, kind: ToastKind.info, key: key);

  /// [actionLabel] and [onAction] go together: a button at the end ("Undo",
  /// "View") and a thin bar counting down the time left to press it.
  void show(
    String message, {
    ToastKind kind = ToastKind.info,
    Key? key,
    String? actionLabel,
    VoidCallback? onAction,
    Key? actionKey,
  }) {
    assert((actionLabel == null) == (onAction == null));
    final overlay = _overlay;
    if (overlay == null || !overlay.mounted) return;
    dismissCurrent();

    late final _Shown shown;
    final entry = OverlayEntry(
      builder: (_) => KeyedSubtree(
        key: viewKey,
        child: _ToastView(
          key: key,
          message: message,
          kind: kind,
          actionLabel: actionLabel,
          onAction: onAction,
          actionKey: actionKey,
          onClosed: () => shown.close(),
        ),
      ),
    );
    shown = _Shown(overlay, entry);
    _current = shown;
    overlay.insert(entry);
  }

  /// Takes the toast on screen down at once, if there is one.
  static void dismissCurrent() => _current?.close();
}

class _Shown {
  _Shown(this.overlay, this.entry);

  final OverlayState overlay;
  final OverlayEntry entry;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    if (identical(NowaToast._current, this)) NowaToast._current = null;
    // Gone with its tree (a test that ended, an app torn down): nothing left
    // to remove it from.
    if (!overlay.mounted) return;
    entry
      ..remove()
      ..dispose();
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    super.key,
    required this.message,
    required this.kind,
    required this.onClosed,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String message;
  final ToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final VoidCallback onClosed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  /// Long enough to read a line; an error or an offer to undo gets longer.
  static const _short = Duration(seconds: 3);
  static const _long = Duration(seconds: 4);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();

  /// Runs only when there is an action: it draws the countdown bar.
  AnimationController? _countdown;
  Timer? _timer;
  double _drag = 0;
  bool _leaving = false;

  bool get _hasAction => widget.actionLabel != null;

  @override
  void initState() {
    super.initState();
    final life = _hasAction || widget.kind == ToastKind.error ? _long : _short;
    _timer = Timer(life, _leave);
    if (_hasAction) {
      _countdown = AnimationController(vsync: this, duration: life)..forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    _countdown?.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    await _entrance.reverse();
    widget.onClosed();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_drag < -24 || (details.primaryVelocity ?? 0) < -300) {
      _leave();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FadeTransition(
            opacity: _entrance,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -1.4),
                end: Offset.zero,
              ).animate(curved),
              child: Transform.translate(
                offset: Offset(0, _drag),
                child: GestureDetector(
                  onVerticalDragUpdate: (d) => setState(
                    () => _drag = (_drag + d.delta.dy).clamp(-120.0, 0.0),
                  ),
                  onVerticalDragEnd: _onDragEnd,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      child: _card(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    final (icon, tint) = switch (widget.kind) {
      ToastKind.success => (Icons.check_rounded, NowaColors.supportInk),
      ToastKind.error => (Icons.priority_high_rounded, NowaColors.danger),
      ToastKind.info => (Icons.info_outline_rounded, NowaColors.text),
    };
    final radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: NowaColors.surface.withValues(alpha: 0.88),
              borderRadius: radius,
              border: Border.all(
                color: widget.kind == ToastKind.error
                    ? NowaColors.danger.withValues(alpha: 0.45)
                    : NowaColors.hairline,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, _hasAction ? 4 : 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 15, color: tint),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: work(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (_hasAction) ...[
                        Container(
                          width: 1,
                          height: 22,
                          margin: const EdgeInsets.only(left: 8),
                          color: NowaColors.hairline,
                        ),
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            key: widget.actionKey,
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              widget.onAction!();
                              _leave();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: sora(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: NowaColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_countdown case final countdown?)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: countdown,
                      builder: (_, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1 - countdown.value,
                        child: Container(
                          height: 2,
                          color: NowaColors.accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
