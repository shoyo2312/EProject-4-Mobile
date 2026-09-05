import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

/// Answers every request with [body] and remembers what was asked.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Map<String, dynamic> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> searchBody(
  List<String> ids, {
  int number = 0,
  int totalPages = 1,
}) =>
    {
      'success': true,
      'data': {
        'content': [
          for (final id in ids) {'id': id, 'title': 'title $id'},
        ],
        'pageable': {'pageNumber': number, 'pageSize': 24},
        'number': number,
        'size': 24,
        'totalElements': totalPages * 24,
        'totalPages': totalPages,
        'last': number + 1 >= totalPages,
      },
    };

void main() {
  late MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  ({SearchRemoteDatasource datasource, _StubAdapter adapter}) build(
    Map<String, dynamic> body,
  ) {
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final adapter = _StubAdapter(body);
    apiClient.dio.httpClientAdapter = adapter;
    return (datasource: SearchRemoteDatasource(apiClient), adapter: adapter);
  }

  test('reads ids off the raw Spring Page shape, in relevance order', () async {
    // search-service serialises Page directly: content/number/totalPages sit
    // at the top level, not under a nested `page` object.
    final ctx = build(searchBody(['7312458901234567', '7312458901234512']));

    final page = await ctx.datasource.searchVideos(query: 'dance');

    expect(page.ids, ['7312458901234567', '7312458901234512']);
    expect(page.last, isTrue);
    expect(ctx.adapter.lastRequest?.queryParameters['q'], 'dance');
  });

  test('ids stay strings — a Snowflake would not survive an int', () async {
    final ctx = build(searchBody(['7312458901234567']));

    final page = await ctx.datasource.searchVideos(query: 'x');

    expect(page.ids.single, '7312458901234567');
  });

  test('last is false while pages remain, whatever the page holds', () async {
    final ctx = build(searchBody(['v1'], number: 0, totalPages: 3));

    final page = await ctx.datasource.searchVideos(query: 'dance');

    expect(page.last, isFalse);
  });

  test('omits q and hashtag entirely when not given', () async {
    final ctx = build(searchBody([]));

    await ctx.datasource.searchVideos(hashtag: 'dance', page: 2);

    final query = ctx.adapter.lastRequest!.queryParameters;
    expect(query.containsKey('q'), isFalse);
    expect(query['hashtag'], 'dance');
    expect(query['page'], 2);
  });
}
