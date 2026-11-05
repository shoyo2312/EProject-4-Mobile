import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';

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

void main() {
  late MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  ({CommentRemoteDatasource datasource, _StubAdapter adapter}) build(
    Map<String, dynamic> body,
  ) {
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final adapter = _StubAdapter(body);
    apiClient.dio.httpClientAdapter = adapter;
    return (datasource: CommentRemoteDatasource(apiClient), adapter: adapter);
  }

  test('a report names the comment by its videoId:commentId pair', () async {
    final ctx = build({'success': true, 'data': {}});

    await ctx.datasource.reportComment('11', '22', 'Hate and harassment');

    expect(ctx.adapter.lastRequest?.method, 'POST');
    expect(ctx.adapter.lastRequest?.path, endsWith('/admin/reports'));
    expect(ctx.adapter.lastRequest?.data, {
      'targetType': 'COMMENT',
      'targetId': '11:22',
      'reason': 'Hate and harassment',
    });
  });

  test('an admin removal goes to admin-service with its reason', () async {
    final ctx = build({'success': true, 'data': {}});

    await ctx.datasource.removeCommentAsAdmin('11', '22', 'Frauds and scams');

    expect(ctx.adapter.lastRequest?.method, 'POST');
    expect(
      ctx.adapter.lastRequest?.path,
      endsWith('/admin/comments/11/22/remove'),
    );
    expect(ctx.adapter.lastRequest?.data, {'reason': 'Frauds and scams'});
  });

  test('a held comment comes back with its status', () async {
    final ctx = build({
      'success': true,
      'data': {
        'commentId': 1,
        'videoId': 2,
        'userId': 3,
        'content': 'hi',
        'createdAt': '2026-01-01T00:00:00Z',
        'status': 'HELD',
      },
    });

    final created = await ctx.datasource.postComment('2', 'hi');

    expect(created.status, CommentStatus.held);
  });

  test('a comment without a status reads as visible', () {
    final comment = CommentModel.fromJson({
      'commentId': 1,
      'videoId': 2,
      'userId': 3,
      'content': 'hi',
      'createdAt': '2026-01-01T00:00:00Z',
    });

    expect(comment.status, CommentStatus.visible);
  });

  test('a reply and a sticker go up as parentId (a number) and stickerId',
      () async {
    final ctx = build({
      'success': true,
      'data': {
        'commentId': 9,
        'videoId': 2,
        'userId': 3,
        'content': '',
        'createdAt': '2026-01-01T00:00:00Z',
        'parentId': 5,
        'replyToUserId': 7,
        'sticker': {'stickerId': 'cat', 'url': 'http://x/cat.png', 'width': 160, 'height': 120},
      },
    });

    final created = await ctx.datasource
        .postComment('2', '', parentId: '5', stickerId: 'cat');

    expect(ctx.adapter.lastRequest?.data, {'parentId': 5, 'stickerId': 'cat'});
    expect(created.parentId, '5');
    expect(created.replyToUserId, '7');
    expect(created.isReply, isTrue);
    expect(created.text, '');
    expect(created.sticker?.stickerId, 'cat');
    expect(created.sticker?.height, 120);
  });

  test('a plain comment sends only its content', () async {
    final ctx = build({
      'success': true,
      'data': {
        'commentId': 1,
        'videoId': 2,
        'userId': 3,
        'content': 'hi',
        'createdAt': '2026-01-01T00:00:00Z',
      },
    });

    await ctx.datasource.postComment('2', 'hi');

    expect(ctx.adapter.lastRequest?.data, {'content': 'hi'});
  });

  test('an edit is a PATCH of the content alone', () async {
    final ctx = build({
      'success': true,
      'data': {
        'commentId': 22,
        'videoId': 11,
        'userId': 3,
        'content': 'fixed',
        'createdAt': '2026-01-01T00:00:00Z',
        'editedAt': '2026-01-02T00:00:00Z',
      },
    });

    final updated = await ctx.datasource.editComment('11', '22', 'fixed');

    expect(ctx.adapter.lastRequest?.method, 'PATCH');
    expect(ctx.adapter.lastRequest?.path,
        endsWith('/interactions/videos/11/comments/22'));
    expect(ctx.adapter.lastRequest?.data, {'content': 'fixed'});
    expect(updated.editedAt, isNotNull);
  });

  test('replies are read from the thread endpoint', () async {
    final ctx = build({
      'success': true,
      'data': {'items': [], 'hasMore': false, 'nextCursor': null},
    });

    await ctx.datasource.fetchReplies('11', '22', cursor: 'abc');

    expect(ctx.adapter.lastRequest?.path,
        endsWith('/interactions/videos/11/comments/22/replies'));
    expect(ctx.adapter.lastRequest?.queryParameters['cursor'], 'abc');
    // Replies read as a conversation, oldest first: never ranked.
    expect(ctx.adapter.lastRequest?.queryParameters.containsKey('sort'), isFalse);
  });

  test('the comment list asks for the most interaction first', () async {
    final ctx = build({
      'success': true,
      'data': {'items': [], 'hasMore': false, 'nextCursor': null},
    });

    await ctx.datasource.fetchComments('11', cursor: 'top.20');

    expect(ctx.adapter.lastRequest?.path,
        endsWith('/interactions/videos/11/comments'));
    expect(ctx.adapter.lastRequest?.queryParameters['sort'], 'top');
    expect(ctx.adapter.lastRequest?.queryParameters['cursor'], 'top.20');
  });
}
