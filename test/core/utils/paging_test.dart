import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';

void main() {
  test('drops a second call while the first is still in flight', () async {
    final guard = LoadMoreGuard();
    final gate = Completer<void>();
    var calls = 0;

    final first = guard.run(() async {
      calls++;
      await gate.future;
    });
    // What a fast scroll does: fire again before the first page comes back.
    await guard.run(() async => calls++);

    gate.complete();
    await first;

    expect(calls, 1);
  });

  test('lets the next call through once the first finishes', () async {
    final guard = LoadMoreGuard();
    var calls = 0;

    await guard.run(() async => calls++);
    await guard.run(() async => calls++);

    expect(calls, 2);
  });

  test('does nothing once the last page has been read', () async {
    final guard = LoadMoreGuard()..done = true;
    var calls = 0;

    await guard.run(() async => calls++);

    expect(calls, 0);
  });

  test('swallows AppException and stays usable', () async {
    final guard = LoadMoreGuard();
    var calls = 0;

    await guard.run(() async {
      calls++;
      throw const NetworkException();
    });
    // The failed page must not leave the guard busy forever.
    await guard.run(() async => calls++);

    expect(calls, 2);
  });
}
