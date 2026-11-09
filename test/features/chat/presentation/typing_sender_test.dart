import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/chat/presentation/typing_sender.dart';

// testWidgets for its fake clock: tester.pump(d) moves every Timer along.
void main() {
  late List<bool> sent;
  late bool socketUp;
  late StreamController<void> lost;

  TypingSender sender() {
    sent = [];
    socketUp = true;
    lost = StreamController<void>.broadcast(sync: true);
    final s = TypingSender(
      send: (typing) {
        if (!socketUp) return false;
        sent.add(typing);
        return true;
      },
      connectionLost: lost.stream,
    );
    addTearDown(() {
      s.dispose();
      lost.close();
    });
    return s;
  }

  testWidgets('one frame per heartbeat, not one per keystroke', (tester) async {
    final s = sender();
    s.input(true);
    s.input(true);
    await tester.pump(const Duration(seconds: 1));
    s.input(true);
    expect(sent, [true]);

    await tester.pump(typingHeartbeat);
    s.input(true);
    expect(sent, [true, true]);
    s.stop();
  });

  testWidgets('stops by itself after a pause in typing', (tester) async {
    final s = sender();
    s.input(true);
    await tester.pump(typingIdle - const Duration(milliseconds: 100));
    expect(sent, [true]);
    // A keystroke pushes the stop back (and, the heartbeat being due, renews).
    s.input(true);
    await tester.pump(const Duration(seconds: 3));
    expect(sent, [true, true]);

    await tester.pump(const Duration(seconds: 1));
    expect(sent, [true, true, false]);
    expect(s.isTyping, isFalse);
  });

  testWidgets('an emptied box stops at once; stopping twice says it once',
      (tester) async {
    final s = sender();
    s.input(true);
    s.input(false);
    s.stop();
    expect(sent, [true, false]);
  });

  testWidgets('nothing is on until a frame really went out', (tester) async {
    final s = sender();
    socketUp = false;
    s.input(true);
    expect(s.isTyping, isFalse);
    s.stop();
    expect(sent, isEmpty);

    socketUp = true;
    s.input(true);
    expect(sent, [true]);
    s.stop();
  });

  testWidgets('a dropped connection forgets, sends nothing, replays nothing',
      (tester) async {
    final s = sender();
    s.input(true);
    lost.add(null);
    expect(s.isTyping, isFalse);
    await tester.pump(typingIdle);
    expect(sent, [true]);

    // Only new input starts it again.
    s.input(true);
    expect(sent, [true, true]);
    s.stop();
  });

  testWidgets('leaving the screen stops', (tester) async {
    final s = sender();
    s.input(true);
    s.dispose();
    expect(sent, [true, false]);
  });
}
