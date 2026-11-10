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
import 'package:tiktok_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
    id: '1001',
    username: 'me',
    email: 'me@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 3, 4),
  );
}

final t0 = DateTime.utc(2026, 11, 6, 10);

MessageModel msg(
  String id, {
  String sender = '2002',
  int minute = 0,
  String content = 'hello',
  ReplyQuote? replyTo,
}) => MessageModel(
  id: id,
  conversationId: 'c1',
  senderId: sender,
  content: content,
  sentAt: t0.add(Duration(minutes: minute)),
  replyTo: replyTo,
);

void main() {
  late MockChatRepository repository;
  late MockUserRepository users;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    repository = MockChatRepository();
    users = MockUserRepository();
    when(() => users.getProfiles(any())).thenAnswer(
      (_) async => {
        '2002': const UserProfileModel(
          userId: '2002',
          displayName: 'Lan',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );
    when(() => users.getMyProfile()).thenAnswer(
      (_) async => const UserProfileModel(
        userId: '1001',
        displayName: 'Me',
        followerCount: 0,
        followingCount: 0,
      ),
    );
    when(
      () => repository.markRead(any(), messageId: any(named: 'messageId')),
    ).thenAnswer((_) async {});
    when(() => repository.markDelivered(any(), any())).thenAnswer((_) async {});
    when(
      () => repository.receipts(any()),
    ).thenAnswer((_) async => const ReceiptView(conversationId: 'c1'));
    when(
      () => repository.liveMessages(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repository.inboxEvents(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repository.connectionLost(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.sendTyping(any(), any())).thenReturn(true);
    when(() => repository.listConversations()).thenAnswer(
      (_) async => [
        ConversationModel(
          id: 'c1',
          participantIds: const ['1001', '2002'],
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
    );
    when(() => repository.listRequests()).thenAnswer((_) async => []);
  });

  Future<void> pumpThread(WidgetTester tester, List<MessageModel> items) async {
    when(
      () => repository.listMessages('c1', size: any(named: 'size')),
    ).thenAnswer((_) async => MessagePage(items: items, hasMore: false));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedIn.new),
          chatRepositoryProvider.overrideWithValue(repository),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: const MaterialApp(home: ChatThreadScreen(conversationId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swiping a message left quotes it and sends a reply', (
    tester,
  ) async {
    when(
      () => repository.sendMessage(
        'c1',
        'sure',
        clientRequestId: any(named: 'clientRequestId'),
        replyToMessageId: 'm1',
      ),
    ).thenAnswer(
      (_) async => msg(
        'm2',
        sender: '1001',
        minute: 1,
        content: 'sure',
        replyTo: msg('m1', content: 'coffee?').asQuote(),
      ),
    );
    await pumpThread(tester, [msg('m1', content: 'coffee?')]);

    // A short swipe is not enough; past the mark it starts a reply.
    await tester.drag(
      find.byKey(const Key('chat_message_m1')),
      const Offset(-30, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_reply_bar')), findsNothing);
    await tester.drag(
      find.byKey(const Key('chat_message_m1')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_reply_bar')), findsOneWidget);
    expect(find.text('Replying to Lan'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chat_composer_field')),
      'sure',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    verify(
      () => repository.sendMessage(
        'c1',
        'sure',
        clientRequestId: any(named: 'clientRequestId'),
        replyToMessageId: 'm1',
      ),
    ).called(1);
    expect(find.byKey(const Key('chat_reply_bar')), findsNothing);
    expect(find.text('You replied to Lan'), findsOneWidget);
    expect(find.byKey(const Key('chat_quote_m1')), findsOneWidget);

    // Tapping the quote finds the original; nothing to fetch, no complaint.
    await tester.tap(find.byKey(const Key('chat_quote_m1')));
    await tester.pumpAndSettle();
    expect(find.text('That message is no longer in this chat'), findsNothing);
  });

  testWidgets('a reaction picked from the long press shows under it', (
    tester,
  ) async {
    when(() => repository.react('c1', 'm1', '😂')).thenAnswer(
      (_) async => const MessageUpdate(
        messageId: 'm1',
        conversationId: 'c1',
        revision: 1,
        reactions: [MessageReaction(userId: '1001', emoji: '😂')],
      ),
    );
    when(() => repository.unreact('c1', 'm1')).thenAnswer(
      (_) async => const MessageUpdate(
        messageId: 'm1',
        conversationId: 'c1',
        revision: 2,
        reactions: [],
      ),
    );
    await pumpThread(tester, [msg('m1')]);

    await tester.longPress(find.byKey(const Key('chat_message_m1')));
    await tester.pumpAndSettle();
    // The second of the six.
    await tester.tap(find.byKey(const Key('chat_react_1')));
    await tester.pumpAndSettle();

    verify(() => repository.react('c1', 'm1', '😂')).called(1);
    final pill = find.byKey(const Key('chat_reaction_m1_😂'));
    expect(pill, findsOneWidget);

    // Tapping one's own pill takes it back.
    await tester.tap(pill);
    await tester.pumpAndSettle();
    verify(() => repository.unreact('c1', 'm1')).called(1);
    expect(pill, findsNothing);
  });

  testWidgets('a request waiting to be accepted offers no reply or reaction', (
    tester,
  ) async {
    when(() => repository.listConversations()).thenAnswer((_) async => []);
    when(() => repository.listRequests()).thenAnswer(
      (_) async => [
        ConversationModel(
          id: 'c1',
          participantIds: const ['1001', '2002'],
          createdAt: DateTime(2026, 8, 1),
          requestState: MessageRequestState.pending,
          initiatorId: '2002',
          sendPermission: SendPermission.awaitingAccept,
        ),
      ],
    );
    await pumpThread(tester, [msg('m1')]);

    await tester.drag(
      find.byKey(const Key('chat_message_m1')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_reply_bar')), findsNothing);

    await tester.longPress(find.byKey(const Key('chat_message_m1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_react_0')), findsNothing);
    expect(find.byKey(const Key('chat_action_hide')), findsOneWidget);
  });
}
