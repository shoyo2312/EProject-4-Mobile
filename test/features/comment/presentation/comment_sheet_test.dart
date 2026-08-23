import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  testWidgets('renders existing comments and posts a new one', (tester) async {
    final commentRepository = MockCommentRepository();
    final existing = CommentModel(
      id: 'c1',
      videoId: 'v1',
      userId: 'u1',
      text: 'first comment',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [existing], hasMore: false, nextCursor: null),
    );
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any())).thenAnswer(
      (_) async => {
        'u1': const UserProfileModel(
          userId: 'u1',
          displayName: 'jane',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );
    when(() => commentRepository.postComment('v1', 'new one')).thenAnswer(
      (_) async => CommentModel(
        id: 'c2',
        videoId: 'v1',
        userId: 'u2',
        text: 'new one',
        createdAt: DateTime(2026, 1, 2),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(commentRepository),
          userRepositoryProvider.overrideWithValue(userRepository),
          // Signed-out viewers get a "log in to comment" prompt, not the input.
          authStateProvider.overrideWith(_SignedInAuthState.new),
        ],
        child: const MaterialApp(home: Scaffold(body: CommentSheet(videoId: 'v1'))),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('first comment'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('comment_input_field')), 'new one');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    verify(() => commentRepository.postComment('v1', 'new one')).called(1);
  });
}

class _SignedInAuthState extends AuthState {
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
