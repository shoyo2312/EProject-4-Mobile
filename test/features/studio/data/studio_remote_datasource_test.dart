import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/data/studio_remote_datasource.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

/// Answers every request with [body] and remembers what was asked.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Object body;
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

Map<String, dynamic> _envelope(Object? data) => {
      'success': true,
      'data': data,
      'timestamp': '2026-11-07T00:00:00Z',
    };

Map<String, dynamic> _video(String id) => {
      'id': id,
      'userId': 1001,
      'title': 'Trip',
      'status': 'PENDING_REVIEW',
      'visibility': 'PUBLIC',
      'viewCount': 1,
      'likeCount': 2,
      'commentCount': 3,
      'createdAt': '2026-11-01T00:00:00Z',
      'pinnedAt': '2026-11-02T00:00:00Z',
    };

void main() {
  late MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  ({StudioRemoteDatasource datasource, _StubAdapter adapter}) build(
    Object body,
  ) {
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final adapter = _StubAdapter(body);
    apiClient.dio.httpClientAdapter = adapter;
    return (datasource: StudioRemoteDatasource(apiClient), adapter: adapter);
  }

  test('top videos ask for the window, the sort and the limit', () async {
    final ctx = build(_envelope([
      {'videoId': '9', 'views': 5},
    ]));

    final rows =
        await ctx.datasource.getTopVideos(28, CreatorVideoSort.newViewers);

    expect(ctx.adapter.lastRequest?.path, endsWith('/analytics/creator/videos/top'));
    expect(ctx.adapter.lastRequest?.queryParameters, {
      'days': 28,
      'sort': 'NEW_VIEWERS',
      'limit': 10,
    });
    expect(rows.single.videoId, '9');
  });

  test('the posts list sends list filters comma-separated', () async {
    final ctx = build(_envelope({
      'content': [_video('1')],
      'page': {'size': 20, 'number': 0, 'totalElements': 1, 'totalPages': 1},
    }));

    final page = await ctx.datasource.listMyVideos(
      const StudioPostQuery(
        statuses: ['PENDING_MODERATION', 'PENDING_REVIEW'],
        visibilities: ['PRIVATE'],
        views: [CountRange.under1k, CountRange.over100k],
        sort: StudioPostSort.likes,
        descending: false,
        q: '  trip ',
      ),
      page: 2,
    );

    expect(ctx.adapter.lastRequest?.path, endsWith('/videos/me'));
    expect(ctx.adapter.lastRequest?.queryParameters, {
      'status': 'PENDING_MODERATION,PENDING_REVIEW',
      'visibility': 'PRIVATE',
      'views': 'UNDER_1K,OVER_100K',
      'q': 'trip',
      'sort': 'LIKES',
      'order': 'ASC',
      'page': 2,
      'size': 20,
    });
    expect(page.content.single.pinnedAt, isNotNull);
    expect(page.last, isTrue);
  });

  test('an unfiltered posts list sends no empty filters', () async {
    final ctx = build(_envelope({
      'content': <Object>[],
      'page': {'size': 20, 'number': 0, 'totalElements': 0, 'totalPages': 0},
    }));

    await ctx.datasource.listMyVideos(const StudioPostQuery());

    expect(ctx.adapter.lastRequest?.queryParameters, {
      'sort': 'NEWEST',
      'order': 'DESC',
      'page': 0,
      'size': 20,
    });
  });

  test('caption and pin are PATCHes with their bodies', () async {
    final ctx = build(_envelope(_video('5')));

    await ctx.datasource.updateCaption('5', title: 'New', description: 'Desc');
    expect(ctx.adapter.lastRequest?.method, 'PATCH');
    expect(ctx.adapter.lastRequest?.path, endsWith('/videos/5/caption'));
    expect(ctx.adapter.lastRequest?.data, {'title': 'New', 'description': 'Desc'});

    await ctx.datasource.setPinned('5', true);
    expect(ctx.adapter.lastRequest?.path, endsWith('/videos/5/pin'));
    expect(ctx.adapter.lastRequest?.data, {'pinned': true});
  });

  test('the inbox sends sort and replied only with a video picked', () async {
    final ctx = build(_envelope({
      'items': [
        {
          'commentId': 1,
          'videoId': 5,
          'userId': 7,
          'content': 'hi',
          'createdAt': '2026-11-01T00:00:00Z',
          'status': 'HELD',
        },
      ],
      'nextCursor': 'abc',
      'hasMore': true,
    }));

    await ctx.datasource.listInbox(
      const InboxQuery(sort: InboxSort.mostLiked, replied: false, heldOnly: true),
    );
    expect(ctx.adapter.lastRequest?.queryParameters, {'status': 'HELD', 'size': 20});

    final page = await ctx.datasource.listInbox(
      const InboxQuery(videoId: '5', sort: InboxSort.mostLiked, replied: false),
      cursor: 'abc',
    );
    expect(ctx.adapter.lastRequest?.path, endsWith('/interactions/users/me/comments'));
    expect(ctx.adapter.lastRequest?.queryParameters, {
      'videoId': '5',
      'sort': 'MOST_LIKED',
      'replied': false,
      'cursor': 'abc',
      'size': 20,
    });
    expect(page.hasMore, isTrue);
    expect(page.nextCursor, 'abc');
    expect(page.items.single.videoId, '5');
  });

  test('approve posts to the video-scoped comment path', () async {
    final ctx = build(_envelope(null));

    await ctx.datasource.approveComment('5', '9');

    expect(ctx.adapter.lastRequest?.method, 'POST');
    expect(
      ctx.adapter.lastRequest?.path,
      endsWith('/interactions/videos/5/comments/9/approve'),
    );
  });
}
