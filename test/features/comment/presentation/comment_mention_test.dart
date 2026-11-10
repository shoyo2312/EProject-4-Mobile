import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
    id: '1',
    username: 'jane',
    email: 'jane@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _NoStories extends Fake implements StoryRepository {
  @override
  Future<List<StoryRing>> rings(List<String> userIds) async => const [];
}

UserProfileModel person(String id, String name, String handle) =>
    UserProfileModel(
      userId: id,
      username: handle,
      displayName: name,
      followerCount: 0,
      followingCount: 0,
    );

PageResponse<UserProfileModel> page(List<UserProfileModel> people) =>
    PageResponse(
      content: people,
      size: 50,
      number: 0,
      totalElements: people.length,
      totalPages: 1,
    );

void main() {
  late MockCommentRepository comments;
  late MockUserRepository users;

  setUp(() {
    comments = MockCommentRepository();
    users = MockUserRepository();
    when(() => comments.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
        items: [
          CommentModel(
            id: 'c1',
            videoId: 'v1',
            userId: 'u9',
            text: 'nice one @lan99 haha',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        hasMore: false,
        nextCursor: null,
      ),
    );
    when(
      () => users.getProfiles(any()),
    ).thenAnswer((_) async => <String, UserProfileModel>{});
    // Lan and the user follow each other; Minh is followed but does not
    // follow back.
    when(() => users.getFollowing('1', page: 0, size: 50)).thenAnswer(
      (_) async => page([
        person('2', 'Lan Nguyen', 'lan99'),
        person('3', 'Minh', 'minh'),
      ]),
    );
    when(
      () => users.getFollowers('1', page: 0, size: 50),
    ).thenAnswer((_) async => page([person('2', 'Lan Nguyen', 'lan99')]));
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(comments),
          userRepositoryProvider.overrideWithValue(users),
          storyRepositoryProvider.overrideWithValue(_NoStories()),
          authStateProvider.overrideWith(_SignedIn.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CommentSheet(videoId: 'v1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final field = find.byKey(const Key('comment_input_field'));

  testWidgets('typing @ offers only friends who follow back', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(field, 'hi @');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('comment_mention_2')), findsOneWidget);
    expect(find.byKey(const Key('comment_mention_3')), findsNothing);

    await tester.tap(find.byKey(const Key('comment_mention_2')));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'hi @lan99 ');
    expect(find.byKey(const Key('comment_mention_suggestions')), findsNothing);
  });

  testWidgets('a comment tagging someone who is not a friend is held back', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.enterText(field, 'look @minh');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('comment_mention_refused')), findsOneWidget);
    verifyNever(
      () => comments.postComment(
        any(),
        any(),
        parentId: any(named: 'parentId'),
        stickerId: any(named: 'stickerId'),
      ),
    );
    expect(tester.widget<TextField>(field).controller!.text, 'look @minh');
  });

  testWidgets('a tag in a comment is drawn as a link', (tester) async {
    await pumpSheet(tester);
    final text = tester.widget<RichText>(
      find
          .descendant(
            of: find.byKey(const Key('comment_text_c1')),
            matching: find.byType(RichText),
          )
          .first,
    );
    final spans = <TextSpan>[];
    text.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    expect(spans.map((s) => s.text), ['nice one ', '@lan99', ' haha']);
    expect(spans[1].recognizer, isNotNull);
  });
}
