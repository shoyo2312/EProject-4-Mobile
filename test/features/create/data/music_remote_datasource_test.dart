import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/create/data/music_remote_datasource.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

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
        'data': [
          {
            'id': '42',
            'title': 'Calm',
            'artist': 'Someone',
            'durationSeconds': 120,
            'audioUrl': 'https://stream/42',
            'imageUrl': 'https://img/42',
            'licenseUrl': 'http://creativecommons.org/licenses/by/3.0/',
            'shareUrl': 'https://www.jamendo.com/track/42',
          },
        ],
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
  late MusicRemoteDatasource datasource;

  setUp(() {
    final tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    adapter = _StubAdapter();
    apiClient.dio.httpClientAdapter = adapter;
    datasource = MusicRemoteDatasource(apiClient);
  });

  test('searches our own API, never the catalogue directly', () async {
    final tracks = await datasource.search(query: ' chill ', page: 1);

    expect(adapter.lastRequest?.path, endsWith('/videos/music'));
    expect(adapter.lastRequest?.queryParameters, {'q': 'chill', 'page': 1, 'size': 20});
    expect(tracks.single.title, 'Calm');
    expect(tracks.single.durationSeconds, 120);
    expect(tracks.single.licenseUrl, contains('/by/'));
  });

  test('no words asks for the popular page, with no q at all', () async {
    await datasource.search();

    expect(adapter.lastRequest?.queryParameters.containsKey('q'), isFalse);
  });
}
