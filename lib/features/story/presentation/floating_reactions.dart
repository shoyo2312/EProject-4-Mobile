import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';

/// A story reaction as drawn everywhere in the viewer: the bundled 3D
/// picture, or the system emoji if the picture is missing.
class ReactionIcon extends StatelessWidget {
  const ReactionIcon({super.key, required this.reaction, this.size = 28});

  final StoryReaction reaction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          reaction.emoji,
          style: TextStyle(fontSize: size * 0.8, height: 1),
        ),
      ),
    );
    final asset = reaction.asset;
    if (asset == null) return fallback;
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// Wraps a footer and sends reactions floating up out of it — over the story,
/// which keeps taking its own taps: the copies ignore the pointer and are
/// painted outside this widget's box.
///
/// [burst] is a viewer's tap: 3–5 copies from the button. [replay] is the
/// owner opening their own story: what everyone gave it, rising one after
/// another across the footer.
///
/// One ticker drives every copy in flight and stops when the last one is gone,
/// so an idle footer costs nothing. With the system's "reduce motion" setting
/// on, nothing flies.
class FloatingReactions extends StatefulWidget {
  const FloatingReactions({
    super.key,
    required this.child,
    this.rise = 320,
    this.random,
  });

  final Widget child;

  /// How far above its start a copy travels before it is gone.
  final double rise;

  /// Seeded in tests; a fresh generator otherwise.
  final Random? random;

  /// Copies per tap, inclusive.
  static const minPerBurst = 3;
  static const maxPerBurst = 5;

  /// Most copies a replay sends, however many reactions the story has.
  static const maxReplay = 12;

  /// Time between two copies of a replay.
  static const replayGap = Duration(milliseconds: 220);

  /// The longest a burst copy can live, stagger included.
  static const maxLifetime = Duration(milliseconds: 2400);

  /// The longest a replay can take, last copy included.
  static Duration get maxReplayLifetime =>
      replayGap * (maxReplay - 1) + const Duration(milliseconds: 2100);

  @override
  State<FloatingReactions> createState() => FloatingReactionsState();
}

class FloatingReactionsState extends State<FloatingReactions>
    with SingleTickerProviderStateMixin {
  /// Made on the first copy: most viewers never tap, and a ticker made
  /// lazily inside dispose would look up an ancestor that is already gone.
  Ticker? _ticker;
  late final Random _random = widget.random ?? Random();
  final List<_Float> _floats = [];
  Duration _now = Duration.zero;

  /// How many copies are in flight. For tests.
  @visibleForTesting
  int get inFlight => _floats.length;

  bool get _motionAllowed =>
      MediaQuery.maybeDisableAnimationsOf(context) != true;

  RenderBox? get _box {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box : null;
  }

  /// Sends 3–5 copies of [reaction] up from [globalOrigin], the centre of the
  /// button that was tapped.
  void burst(StoryReaction reaction, Offset globalOrigin) {
    final box = _box;
    if (box == null || !_motionAllowed) return;
    final origin = box.globalToLocal(globalOrigin);
    _startClock();
    final count = FloatingReactions.minPerBurst +
        _random.nextInt(
            FloatingReactions.maxPerBurst - FloatingReactions.minPerBurst + 1);
    _launch([
      for (var i = 0; i < count; i++)
        _float(
          reaction,
          origin,
          Duration(milliseconds: i * 90 + _random.nextInt(60)),
          rise: widget.rise * (0.75 + _random.nextDouble() * 0.25),
        ),
    ]);
  }

  /// Sends up what a story was given, at most [FloatingReactions.maxReplay]
  /// copies, each kind in proportion to its count and every kind at least
  /// once, rising from across the top of this widget in a shuffled order.
  void replay(Map<StoryReaction, int> counts) {
    final box = _box;
    if (box == null || !_motionAllowed) return;
    final picks = replayPicks(counts, _random);
    if (picks.isEmpty) return;
    final width = box.size.width;
    _startClock();
    _launch([
      for (var i = 0; i < picks.length; i++)
        _float(
          picks[i],
          Offset(width * (0.2 + _random.nextDouble() * 0.6), 0),
          FloatingReactions.replayGap * i,
          rise: widget.rise * (1.0 + _random.nextDouble() * 0.25),
        ),
    ]);
  }

  /// Which copies a replay sends, in order. Exposed for tests.
  @visibleForTesting
  static List<StoryReaction> replayPicks(
    Map<StoryReaction, int> counts,
    Random random,
  ) {
    final given = {
      for (final e in counts.entries)
        if (e.value > 0 && e.key != StoryReaction.unknown) e.key: e.value,
    };
    final total = given.values.fold(0, (a, b) => a + b);
    if (total == 0) return const [];
    final budget = min(total, FloatingReactions.maxReplay);
    final picks = <StoryReaction>[
      for (final e in given.entries)
        for (var i = 0; i < max(1, (e.value * budget / total).floor()); i++)
          e.key,
    ];
    // Rounding down left room: hand it to the most-given kinds first.
    final byCount = given.keys.toList()
      ..sort((a, b) => given[b]!.compareTo(given[a]!));
    for (var i = 0; picks.length < budget; i++) {
      picks.add(byCount[i % byCount.length]);
    }
    return picks.take(budget).toList()..shuffle(random);
  }

  _Float _float(
    StoryReaction reaction,
    Offset origin,
    Duration delay, {
    required double rise,
  }) =>
      _Float(
        reaction: reaction,
        origin: origin,
        start: _now + delay,
        duration: Duration(milliseconds: 1300 + _random.nextInt(600)),
        size: 30 + _random.nextDouble() * 12,
        drift: (_random.nextDouble() - 0.5) * 60,
        sway: 6 + _random.nextDouble() * 10,
        swayTurns: 1 + _random.nextDouble(),
        phase: _random.nextDouble() * 2 * pi,
        rise: rise,
      );

  /// Before any copy is timed: a ticker that was stopped starts counting
  /// from zero again, and the copies' start times are read off [_now].
  void _startClock() {
    final ticker = _ticker ??= createTicker(_onTick);
    if (!ticker.isActive) {
      _now = Duration.zero;
      ticker.start();
    }
  }

  void _launch(List<_Float> floats) {
    if (floats.isEmpty) return;
    setState(() => _floats.addAll(floats));
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _now = elapsed;
      _floats.removeWhere((f) => _now >= f.start + f.duration);
    });
    if (_floats.isEmpty) _ticker?.stop();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        for (final f in _floats)
          if (_now >= f.start) _positioned(f),
      ],
    );
  }

  Widget _positioned(_Float f) {
    final t = ((_now - f.start).inMicroseconds / f.duration.inMicroseconds)
        .clamp(0.0, 1.0);
    final up = Curves.easeOut.transform(t) * f.rise;
    final x = f.drift * t + sin(f.phase + t * f.swayTurns * 2 * pi) * f.sway;
    // Pops in a little large, settles, then shrinks as it fades.
    final scale = t < 0.15
        ? 0.5 + (t / 0.15) * 0.7
        : 1.2 - (t - 0.15) / 0.85 * 0.35;
    final opacity = t < 0.1
        ? t / 0.1
        : t > 0.6
            ? (1 - (t - 0.6) / 0.4)
            : 1.0;
    return Positioned(
      left: f.origin.dx + x - f.size / 2,
      top: f.origin.dy - up - f.size / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: ReactionIcon(reaction: f.reaction, size: f.size),
          ),
        ),
      ),
    );
  }
}

class _Float {
  const _Float({
    required this.reaction,
    required this.origin,
    required this.start,
    required this.duration,
    required this.size,
    required this.drift,
    required this.sway,
    required this.swayTurns,
    required this.phase,
    required this.rise,
  });

  final StoryReaction reaction;
  final Offset origin;
  final Duration start;
  final Duration duration;
  final double size;

  /// Where it ends up sideways from its start, in px.
  final double drift;

  /// How far it rocks from side to side, and how many times on the way up.
  final double sway;
  final double swayTurns;
  final double phase;
  final double rise;
}
