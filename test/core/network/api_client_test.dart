import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late ApiClient apiClient;

  setUp(() {
    tokenStorage = MockTokenStorage();
    apiClient = ApiClient(tokenStorage: tokenStorage);
  });

  test('attaches Authorization header when access token exists', () async {
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => 'test-token');

    apiClient.dio.httpClientAdapter = _RecordingAdapter();
    final response = await apiClient.get<Map<String, dynamic>>('/ping');

    expect(
      (apiClient.dio.httpClientAdapter as _RecordingAdapter).lastHeaders?['Authorization'],
      'Bearer test-token',
    );
    expect(response.statusCode, 200);
  });

  test('omits Authorization header when no token stored', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

    apiClient.dio.httpClientAdapter = _RecordingAdapter();
    await apiClient.get<Map<String, dynamic>>('/ping');

    expect(
      (apiClient.dio.httpClientAdapter as _RecordingAdapter).lastHeaders?.containsKey('Authorization'),
      false,
    );
  });

  test('on 401, refreshes once and retries the original request', () async {
    // Mirrors production: the interceptor re-reads the access token from
    // storage on every request, so it must reflect what saveTokens wrote.
    var currentAccessToken = 'expired-token';
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => currentAccessToken);
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((invocation) async {
      currentAccessToken = invocation.namedArguments[#accessToken] as String;
    });

    final adapter = _ScriptedAdapter({
      '/protected': [
        () => _jsonResponse(401, {}),
        () => _jsonResponse(200, {'ok': true}),
      ],
      '/auth/refresh': [
        () => _jsonResponse(200, {
              'success': true,
              'data': {
                'accessToken': 'new-token',
                'refreshToken': 'new-refresh',
                'expiresInMillis': 900000,
              },
              'timestamp': '2026-08-01T10:00:00Z',
            }),
      ],
    });
    apiClient.dio.httpClientAdapter = adapter;

    final response = await apiClient.get<Map<String, dynamic>>('/protected');

    expect(response.statusCode, 200);
    expect(adapter.headersByPath['/protected']!.last['Authorization'], 'Bearer new-token');
    verify(() => tokenStorage.saveTokens(
          accessToken: 'new-token',
          refreshToken: 'new-refresh',
        )).called(1);
  });

  test('clears tokens and rethrows when the refresh call also fails', () async {
    String? currentAccessToken = 'expired-token';
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => currentAccessToken);
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => tokenStorage.clear()).thenAnswer((_) async {
      currentAccessToken = null;
    });

    apiClient.dio.httpClientAdapter = _ScriptedAdapter({
      // 401 again for a guest — a genuinely protected endpoint.
      '/protected': [() => _jsonResponse(401, {}), () => _jsonResponse(401, {})],
      '/auth/refresh': [() => _jsonResponse(401, {})],
    });

    await expectLater(
      () => apiClient.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );
    verify(() => tokenStorage.clear()).called(1);
  });

  test('a malformed refresh envelope does not wedge later 401s', () async {
    // The refresh response parses as JSON but has no accessToken, so the casts
    // in _refreshAccessToken throw a TypeError rather than a DioException. If
    // that failure were remembered, every later 401 would reuse the dead
    // future and the client could never recover without a restart.
    String? currentAccessToken = 'expired-token';
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => currentAccessToken);
    when(() => tokenStorage.readRefreshToken())
        .thenAnswer((_) async => 'refresh-token');
    when(() => tokenStorage.clear()).thenAnswer((_) async {
      currentAccessToken = null;
    });
    when(() => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((invocation) async {
      currentAccessToken = invocation.namedArguments[#accessToken] as String;
    });

    final adapter = _ScriptedAdapter({
      '/videos/feed': [
        () => _jsonResponse(401, {}),
        () => _jsonResponse(200, {'ok': true}),
        () => _jsonResponse(401, {}),
        () => _jsonResponse(200, {'ok': true}),
      ],
      '/auth/refresh': [
        () => _jsonResponse(200, {
              'success': true,
              'data': <String, dynamic>{},
              'timestamp': '2026-08-01T10:00:00Z',
            }),
        () => _jsonResponse(200, {
              'success': true,
              'data': {
                'accessToken': 'new-token',
                'refreshToken': 'new-refresh',
                'expiresInMillis': 900000,
              },
              'timestamp': '2026-08-01T10:00:00Z',
            }),
      ],
    });
    apiClient.dio.httpClientAdapter = adapter;

    expect((await apiClient.get<Map<String, dynamic>>('/videos/feed')).statusCode, 200);
    expect((await apiClient.get<Map<String, dynamic>>('/videos/feed')).statusCode, 200);

    // Refreshed twice: the second 401 got a fresh attempt, not the dead one.
    expect(adapter.headersByPath['/auth/refresh']!.length, 2);
    expect(adapter.headersByPath['/videos/feed']!.last['Authorization'],
        'Bearer new-token');
  });

  test('retries anonymously when refresh fails and the path serves guests',
      () async {
    String? currentAccessToken = 'expired-token';
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => currentAccessToken);
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => tokenStorage.clear()).thenAnswer((_) async {
      currentAccessToken = null;
    });

    final adapter = _ScriptedAdapter({
      '/videos/feed': [
        () => _jsonResponse(401, {}),
        () => _jsonResponse(200, {'ok': true}),
      ],
      '/auth/refresh': [() => _jsonResponse(401, {})],
    });
    apiClient.dio.httpClientAdapter = adapter;

    final response = await apiClient.get<Map<String, dynamic>>('/videos/feed');

    expect(response.statusCode, 200);
    expect(
      adapter.headersByPath['/videos/feed']!.last.containsKey('Authorization'),
      false,
    );
  });

  group('jwtExpiry', () {
    String jwt(Map<String, dynamic> claims) =>
        'h.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.s';

    test('reads exp as seconds since the epoch', () {
      expect(ApiClient.jwtExpiry(jwt({'exp': 1700000000})),
          DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    });

    test('anything unreadable is null, which means refresh', () {
      expect(ApiClient.jwtExpiry('not-a-jwt'), isNull);
      expect(ApiClient.jwtExpiry('a.!!!.c'), isNull);
      expect(ApiClient.jwtExpiry(jwt({'sub': '1'})), isNull);
    });

    int secondsFromNow(Duration d) =>
        DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

    test('validAccessToken hands back a token that is still good', () async {
      final token = jwt({'exp': secondsFromNow(const Duration(minutes: 10))});
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => token);

      expect(await apiClient.validAccessToken(), token);
      verifyNever(() => tokenStorage.readRefreshToken());
    });

    test('validAccessToken refreshes a token about to expire', () async {
      // Ten seconds left: under the margin, so a socket opened with it would
      // be closed almost at once.
      final token = jwt({'exp': secondsFromNow(const Duration(seconds: 10))});
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => token);
      when(() => tokenStorage.readRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      apiClient.dio.httpClientAdapter = _ScriptedAdapter({
        '/auth/refresh': [
          () => _jsonResponse(200, {
                'success': true,
                'data': {'accessToken': 'new-token', 'refreshToken': 'r2'},
                'timestamp': '2026-08-01T10:00:00Z',
              }),
        ],
      });

      expect(await apiClient.validAccessToken(), 'new-token');
    });

    test('validAccessToken is null when signed out', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

      expect(await apiClient.validAccessToken(), isNull);
    });
  });
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Minimal fake adapter that always returns 200 with an empty JSON body,
/// recording the headers it was called with so the interceptor can be
/// asserted without a real HTTP server.
class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = options.headers;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Fake adapter that replays a queue of canned responses per request path,
/// so refresh-then-retry sequences can be scripted without a real server.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  final Map<String, List<ResponseBody Function()>> responses;
  final Map<String, List<Map<String, dynamic>>> headersByPath = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headersByPath.putIfAbsent(options.path, () => []).add(options.headers);
    final queue = responses[options.path];
    if (queue == null || queue.isEmpty) {
      throw StateError('No scripted response left for ${options.path}');
    }
    return queue.removeAt(0)();
  }

  @override
  void close({bool force = false}) {}

}
