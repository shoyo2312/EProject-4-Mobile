import 'dart:async';

/// The three clocks of the typing indicator, the same as the web client's and
/// chosen to fit chat-service's own (`TypingService.TTL_MS`, 7s): a renewal
/// every 2.5s keeps a typing session alive with room to lose one frame, the
/// typist's side stops 4s after the last keystroke, and the viewer's side
/// drops the dots 8s after the last frame — a second longer than the server
/// holds them, so the server's "stopped" normally arrives first and this is
/// only the net under a lost frame or a dead connection.
const typingHeartbeat = Duration(milliseconds: 2500);
const typingIdle = Duration(seconds: 4);
const typingPeerTtl = Duration(seconds: 8);

/// Tells the other side that the caller is typing in one thread, and when
/// they stop.
///
/// Driven only by what the person does: [input] is called from the box's own
/// change handler, never because it got focus or a draft was put back. While
/// input continues a frame goes out at most every [typingHeartbeat], not per
/// keystroke; [typingIdle] after the last input it stops by itself. A dropped
/// connection forgets the state without sending anything — there is nothing
/// to send it on — and nothing is replayed after the reconnect.
class TypingSender {
  TypingSender({
    required bool Function(bool typing) send,
    Stream<void>? connectionLost,
  }) : _send = send {
    _lost = connectionLost?.listen((_) => _reset());
  }

  final bool Function(bool typing) _send;
  StreamSubscription<void>? _lost;

  bool _on = false;
  bool _renewDue = false;
  Timer? _idle;
  Timer? _heartbeat;

  /// Whether the other side was last told "typing".
  bool get isTyping => _on;

  /// The box changed because the person did something. [hasText] is whether
  /// it now holds anything worth sending — false (emptied, or not allowed to
  /// send here) stops at once.
  void input(bool hasText) {
    if (!hasText) {
      stop();
      return;
    }
    _idle?.cancel();
    _idle = Timer(typingIdle, stop);
    if (_on && !_renewDue) return;
    // Only counts as on if the frame really went out: a socket that is down
    // says nothing.
    if (!_send(true)) return;
    _on = true;
    _renewDue = false;
    _heartbeat?.cancel();
    _heartbeat = Timer(typingHeartbeat, () => _renewDue = true);
  }

  /// Stops typing now, if it was on.
  void stop() {
    final wasOn = _on;
    _reset();
    if (wasOn) _send(false);
  }

  /// Stops, and lets go of the connection it was watching.
  void dispose() {
    stop();
    _lost?.cancel();
    _lost = null;
  }

  void _reset() {
    _idle?.cancel();
    _heartbeat?.cancel();
    _idle = null;
    _heartbeat = null;
    _on = false;
    _renewDue = false;
  }
}
