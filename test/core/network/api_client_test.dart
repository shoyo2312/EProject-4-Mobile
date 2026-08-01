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
          expiresInMillis: any(named: 'expiresInMillis'),
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
          expiresInMillis: 900000,
        )).called(1);
  });

  test('clears tokens and rethrows when the refresh call also fails', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'expired-token');
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    apiClient.dio.httpClientAdapter = _ScriptedAdapter({
      '/protected': [() => _jsonResponse(401, {})],
      '/auth/refresh': [() => _jsonResponse(401, {})],
    });

    await expectLater(
      () => apiClient.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );
    verify(() => tokenStorage.clear()).called(1);
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
