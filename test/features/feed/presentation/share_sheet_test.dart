import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/share_sheet.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
    id: 'me',
    username: 'me',
    email: 'me@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 3, 4),
  );
}

final video = VideoModel(
  id: 'v1',
  userId: '123',
  title: 'a video',
  hlsUrl: 'https://cdn.test/v1.m3u8',
  status: VideoStatus.published,
  visibility: VideoVisibility.public,
  viewCount: 0,
  likeCount: 0,
  commentCount: 0,
  createdAt: DateTime(2026, 8, 12),
);

void main() {
  late MockChatRepository chat;
  late MockUserRepository users;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    chat = MockChatRepository();
    users = MockUserRepository();
    when(() => chat.inboxEvents()).thenAnswer((_) => const Stream.empty());
    when(() => chat.markDelivered(any(), any())).thenAnswer((_) async {});
    // Seven people; c7 the most recent, c0 the oldest.
    when(() => chat.listConversations()).thenAnswer(
      (_) async => [
        for (var i = 0; i < 7; i++)
          ConversationModel(
            id: 'c$i',
            participantIds: ['me', 'u$i'],
            createdAt: DateTime(2026, 1, 1),
            lastMessageAt: DateTime(2026, 5, 1 + i),
          ),
      ],
    );
    when(() => users.getProfiles(any())).thenAnswer(
      (_) async => {
        for (var i = 0; i < 7; i++)
          'u$i': UserProfileModel(
            userId: 'u$i',
            displayName: 'Person $i',
            followerCount: 0,
            followingCount: 0,
          ),
      },
    );
  });

  Future<Future<bool>> openSheet(WidgetTester tester) async {
    late Future<bool> result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedIn.new),
          chatRepositoryProvider.overrideWithValue(chat),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showShareSheet(context, video: video),
              child: const Text('share'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('the five most recent chats are offered, newest first', (
    tester,
  ) async {
    await openSheet(tester);

    for (var i = 2; i < 7; i++) {
      expect(find.byKey(Key('share_recent_c$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('share_recent_c1')), findsNothing);
    final first = tester.getTopLeft(find.byKey(const Key('share_recent_c6')));
    final second = tester.getTopLeft(find.byKey(const Key('share_recent_c5')));
    expect(first.dx, lessThan(second.dx));
  });

  testWidgets('picking someone and Send puts the video in their chat', (
    tester,
  ) async {
    when(
      () => chat.sendVideo(
        'c6',
        'v1',
        note: any(named: 'note'),
        clientRequestId: any(named: 'clientRequestId'),
      ),
    ).thenAnswer(
      (_) async => MessageModel(
        id: 'm1',
        conversationId: 'c6',
        senderId: 'me',
        content: 'Shared a video',
        sentAt: DateTime(2026, 6, 1),
        type: MessageType.video,
      ),
    );
    final result = await openSheet(tester);

    await tester.tap(find.byKey(const Key('share_recent_c6')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('share_note_field')), 'lol');
    await tester.tap(find.byKey(const Key('share_send_button')));
    await tester.pumpAndSettle();

    verify(
      () => chat.sendVideo(
        'c6',
        'v1',
        note: 'lol',
        clientRequestId: any(named: 'clientRequestId'),
      ),
    ).called(1);
    // chat-service counts a share sent in a chat itself.
    expect(await result, isFalse);
  });

  testWidgets('Messages opens the whole conversation list, searchable', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.byKey(const Key('share_target_messages')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share_conversations')), findsOneWidget);
    // The list is lazy: the newest are built first.
    expect(find.byKey(const Key('share_conversation_c6')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('share_conversations_search')),
      'person 3',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share_conversation_c3')), findsOneWidget);
    expect(find.byKey(const Key('share_conversation_c6')), findsNothing);
  });
}
