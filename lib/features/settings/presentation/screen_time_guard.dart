import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';
import 'package:tiktok_mobile/features/settings/presentation/widgets/settings_widgets.dart';

/// Wraps the whole app, above the navigator, and does what the web's
/// `ScreenTimeGuard` does:
///
/// - counts time in the foreground and sends it as heartbeats, so the
///   summary covers the app as well as the web;
/// - covers the app at the daily limit until the passcode is entered (never
///   on the settings pages, never without a passcode, once a day);
/// - reminds ten minutes before sleep hours, and covers the app during them
///   until "Return for now", which snoozes an hour.
///
/// While either cover is up, tickers below are off — which is what pauses the
/// video players.
class ScreenTimeGuard extends ConsumerStatefulWidget {
  const ScreenTimeGuard({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  /// How often time is counted and the covers are re-checked.
  static const tick = Duration(seconds: 15);

  @override
  ConsumerState<ScreenTimeGuard> createState() => _ScreenTimeGuardState();
}

class _ScreenTimeGuardState extends ConsumerState<ScreenTimeGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;

  /// Seconds counted since [_base] was read, and seconds not sent yet.
  int _counted = 0;
  int _pending = 0;
  bool _sending = false;

  /// Today's total as the server had it, and the local day it is for.
  int? _base;
  String? _baseDate;
  bool _reading = false;

  bool _locked = false;
  bool _sleeping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.router.routerDelegate.addListener(_evaluate);
    _timer = Timer.periodic(ScreenTimeGuard.tick, (_) => _onTick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.router.routerDelegate.removeListener(_evaluate);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      // Back in the app: the limit, sleep hours or today's total may have
      // changed on another device meanwhile.
      ref.read(accountSettingsProvider.notifier).refresh();
      _base = null;
      _evaluate();
    } else if (_pending > 0) {
      _sendHeartbeat();
    }
  }

  String? get _userId => ref.read(authStateProvider).valueOrNull?.id;

  String get _path =>
      widget.router.routerDelegate.currentConfiguration.uri.path;

  void _onTick() {
    if (!_foreground || _userId == null) return;
    final today = localDate(DateTime.now());
    if (_baseDate != null && _baseDate != today) _base = null;
    // Time behind the limit cover is not time spent in the app.
    if (!_locked) {
      _counted += ScreenTimeGuard.tick.inSeconds;
      _pending = math.min(120, _pending + ScreenTimeGuard.tick.inSeconds);
      if (_pending >= 60) _sendHeartbeat();
    }
    _remindBeforeSleep();
    _evaluate();
  }

  Future<void> _sendHeartbeat() async {
    if (_sending || _pending <= 0) return;
    _sending = true;
    final seconds = _pending;
    _pending = 0;
    try {
      await ref
          .read(settingsRepositoryProvider)
          .sendScreenTimeHeartbeat(
            seconds,
            ianaTimeZone(DateTime.now().timeZoneOffset),
          );
    } on AppException {
      // Put them back for the next beat; a long outage loses what is past
      // the server's own 120-second clamp anyway.
      _pending = math.min(120, _pending + seconds);
    } finally {
      _sending = false;
    }
  }

  /// Today's total from the server — the base the limit is counted from.
  /// Only read while there is a limit to enforce.
  Future<void> _readBase() async {
    if (_reading) return;
    _reading = true;
    final now = DateTime.now();
    final today = localDate(now);
    try {
      final week = await ref
          .read(settingsRepositoryProvider)
          .getScreenTimeWeek(weekStartOf(now));
      final day = week.days.where((d) => d.date == today).firstOrNull;
      _base = day?.totalSeconds ?? 0;
      _baseDate = today;
      _counted = 0;
    } on AppException {
      // No read, no lock: the limit is a nudge, not a wall to hit blind.
    } finally {
      _reading = false;
    }
    if (mounted) _evaluate();
  }

  void _remindBeforeSleep() {
    final userId = _userId;
    final start = ref
        .read(accountSettingsProvider)
        .valueOrNull
        ?.sleepHoursStart;
    final store = ref.read(screenTimeLocalStoreProvider).valueOrNull;
    if (userId == null || start == null || store == null) return;
    final night = sleepReminderDue(start, DateTime.now());
    if (night == null || store.reminded(userId, night)) return;
    store.setReminded(userId, night);
    showSettingsMessage(
      context,
      'Sleep hours start in 10 minutes',
      kind: ToastKind.info,
    );
  }

  void _evaluate() {
    if (!mounted) return;
    final userId = _userId;
    final settings = ref.read(accountSettingsProvider).valueOrNull;
    final store = ref.read(screenTimeLocalStoreProvider).valueOrNull;
    var locked = false;
    var sleeping = false;

    if (userId != null && settings != null && store != null) {
      final now = DateTime.now();
      final today = localDate(now);
      final limit = settings.limitFor(now.weekday);
      final guarded = limit != null && settings.hasScreenTimePasscode;
      if (guarded && _base == null) unawaited(_readBase());
      final base = _base;
      locked =
          guarded &&
          base != null &&
          isLocked(
            todaySeconds: base + _counted,
            limitMinutes: limit,
            hasPasscode: settings.hasScreenTimePasscode,
            unlockedDate: store.unlockedDate(userId),
            today: today,
            path: _path,
          );

      final start = settings.sleepHoursStart;
      final snoozed = store.snoozedUntil(userId);
      sleeping =
          start != null &&
          inSleepHours(start, now) &&
          (snoozed == null || !now.isBefore(snoozed));
    }

    if (locked != _locked || sleeping != _sleeping) {
      setState(() {
        _locked = locked;
        _sleeping = sleeping;
      });
    }
  }

  Future<void> _unlocked() async {
    final userId = _userId;
    final store = ref.read(screenTimeLocalStoreProvider).valueOrNull;
    if (userId == null || store == null) return;
    await store.setUnlockedDate(userId, localDate(DateTime.now()));
    _evaluate();
  }

  Future<void> _snooze() async {
    final userId = _userId;
    final store = ref.read(screenTimeLocalStoreProvider).valueOrNull;
    if (userId == null || store == null) return;
    await store.setSnoozedUntil(
      userId,
      DateTime.now().add(const Duration(hours: 1)),
    );
    _evaluate();
    if (mounted) {
      showSettingsMessage(
        context,
        "We'll remind you again after 1 hour on Nowa",
        kind: ToastKind.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check whenever the settings or the account change.
    ref.listen<AsyncValue<UserSettings?>>(
      accountSettingsProvider,
      (_, _) => _evaluate(),
    );
    ref.listen(screenTimeLocalStoreProvider, (_, _) => _evaluate());
    ref.listen(authStateProvider.select((s) => s.valueOrNull?.id), (_, _) {
      _base = null;
      _counted = 0;
      _pending = 0;
      _evaluate();
    });

    final covered = _locked || _sleeping;
    return Stack(
      children: [
        TickerMode(enabled: !covered, child: widget.child),
        if (covered)
          // An Overlay of its own: the covers sit above the app's navigator,
          // and the passcode field needs one for its text handles.
          Positioned.fill(
            child: Overlay(
              // Entries are built once; a new key swaps the cover when the
              // limit is reached during sleep hours, or the other way round.
              key: ValueKey(_locked),
              initialEntries: [
                OverlayEntry(
                  builder: (_) => _locked
                      ? _LimitCover(onUnlocked: _unlocked)
                      : _SleepCover(onReturn: _snooze),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The daily limit reached: only the passcode gets past it.
class _LimitCover extends ConsumerStatefulWidget {
  const _LimitCover({required this.onUnlocked});

  final Future<void> Function() onUnlocked;

  @override
  ConsumerState<_LimitCover> createState() => _LimitCoverState();
}

class _LimitCoverState extends ConsumerState<_LimitCover> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check(String passcode) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final correct = await ref
          .read(settingsRepositoryProvider)
          .verifyScreenTimePasscode(passcode);
      if (correct) {
        await widget.onUnlocked();
        return;
      }
      if (mounted) setState(() => _error = 'Incorrect passcode');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = settingsErrorMessage(e));
    } finally {
      if (mounted) {
        _controller.clear();
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Cover(
      coverKey: const Key('screen_time_limit_cover'),
      icon: Icons.hourglass_bottom,
      title: "You've reached your daily screen time limit",
      text: 'Enter your passcode to keep using Nowa today.',
      children: [
        const SizedBox(height: 26),
        PasscodeField(
          controller: _controller,
          enabled: !_checking,
          error: _error != null,
          onCompleted: _check,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 20,
          child: _error == null
              ? null
              : Text(
                  _error!,
                  key: const Key('screen_time_limit_error'),
                  textAlign: TextAlign.center,
                  style: work(size: 13, color: NowaColors.danger),
                ),
        ),
      ],
    );
  }
}

class _SleepCover extends StatelessWidget {
  const _SleepCover({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return _Cover(
      coverKey: const Key('sleep_hours_cover'),
      icon: Icons.bedtime_outlined,
      title: 'Sleep hours',
      text: 'Unwind with a breathing exercise for a good night’s sleep.',
      children: [
        const SizedBox(height: 30),
        SizedBox(
          width: 200,
          child: NowaButton(
            key: const Key('sleep_hours_return'),
            label: 'Return for now',
            onTap: onReturn,
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.coverKey,
    required this.icon,
    required this.title,
    required this.text,
    required this.children,
  });

  final Key coverKey;
  final IconData icon;
  final String title;
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: coverKey,
      color: NowaColors.bg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: NowaColors.accent),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: sora(size: 20, spacing: -0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: work(size: 13.5, height: 1.5, color: NowaColors.dim),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
