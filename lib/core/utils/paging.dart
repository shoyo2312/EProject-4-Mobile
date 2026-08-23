import 'package:tiktok_mobile/core/network/app_exception.dart';

/// Serialises the "load the next page" calls that infinite lists fire from
/// scroll and page-change callbacks.
///
/// Those callbacks cannot await, so without this every fast scroll starts a
/// second request against the same cursor and a failed page becomes an
/// unhandled async error with nothing on screen to show for it.
class LoadMoreGuard {
  bool _busy = false;

  /// Set from the paging state: no page left to fetch.
  bool done = false;

  /// Runs [load] unless the last page has been read or a call is still in
  /// flight. A failed page keeps the rows already on screen — the next scroll
  /// retries — rather than replacing them with an error.
  Future<void> run(Future<void> Function() load) async {
    if (done || _busy) return;
    _busy = true;
    try {
      await load();
    } on AppException {
      // Deliberately swallowed; see above.
    } finally {
      _busy = false;
    }
  }
}
