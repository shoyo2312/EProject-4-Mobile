import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_remote_datasource.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

/// Answers a repost the way the server does: reposted unless it was a DELETE.
class _StubAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'videoId': 11,
          'reposted': options.method != 'DELETE',
          'repostCount': 1,
        },
        'timestamp': '2026-11-05T00:00:00Z',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _StubAdapter adapter;
  late InteractionRemoteDatasource datasource;

  setUp(() {
    final tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    adapter = _StubAdapter();
    apiClient.dio.httpClientAdapter = adapter;
    datasource = InteractionRemoteDatasource(apiClient);
  });

  test('a repost is a POST on the video, answered with its new state',
      () async {
    final reposted = await datasource.repost('11');

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path,
        endsWith('/interactions/videos/11/repost'));
    expect(reposted, isTrue);
  });

  test('undoing it is a DELETE on the same path', () async {
    final reposted = await datasource.unrepost('11');

    expect(adapter.lastRequest?.method, 'DELETE');
    expect(adapter.lastRequest?.path,
        endsWith('/interactions/videos/11/repost'));
    expect(reposted, isFalse);
  });
}
