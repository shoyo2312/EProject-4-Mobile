import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedInAuthState extends AuthState {
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

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

MessageModel message(String id, {String sender = '2002'}) => MessageModel(
      id: id,
      conversationId: 'c1',
      senderId: sender,
      content: 'message $id',
      sentAt: DateTime(2026, 9, 1),
    );

ConversationModel conversation({String id = 'c1', bool hasUnread = false}) =>
    ConversationModel(
      id: id,
      participantIds: const ['1001', '2002'],
      lastMessageContent: 'hi',
      createdAt: DateTime(2026, 8, 1),
      hasUnread: hasUnread,
    );

void main() {
  late MockChatRepository repository;
  late MockUserRepository userRepository;

  setUp(() {
    repository = MockChatRepository();
    userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any()))
        .thenAnswer((_) async => <String, UserProfileModel>{});
    when(() => repository.markRead(any())).thenAnswer((_) async {});
    when(() => repository.liveMessages(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.inboxEvents())
        .thenAnswer((_) => const Stream.empty());
  });

  ProviderContainer containerFor({bool signedIn = true}) {
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(
        signedIn ? _SignedInAuthState.new : _SignedOutAuthState.new,
      ),
      chatRepositoryProvider.overrideWithValue(repository),
      userRepositoryProvider.overrideWithValue(userRepository),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('a guest lists no conversations instead of a 401', () async {
    final container = containerFor(signedIn: false);

    expect(await container.read(conversationsProvider.future), isEmpty);
    verifyNever(() => repository.listConversations());
  });

  test('the thread list resolves its avatars in one batch', () async {
    when(() => repository.listConversations())
        .thenAnswer((_) async => [conversation()]);

    final container = containerFor();
    await container.read(conversationsProvider.future);

    // The other participant, not the caller.
    final asked = verify(() => userRepository.getProfiles(captureAny()))
        .captured
        .single as Iterable<String>;
    expect(asked, ['2002']);
  });

  test('opening a thread loads a page and clears its unread flag', () async {
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => MessagePage(
              items: [message('m2'), message('m1')],
              hasMore: false,
            ));

    final container = containerFor();
    final messages = await container.read(threadProvider('c1').future);

    expect(messages.map((m) => m.id), ['m2', 'm1']);
    verify(() => repository.markRead('c1')).called(1);
  });

  test('a message arriving on the socket lands at the top, once', () async {
    final socket = StreamController<MessageModel>.broadcast();
    addTearDown(socket.close);
    when(() => repository.liveMessages('c1'))
        .thenAnswer((_) => socket.stream);
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async =>
            MessagePage(items: [message('m1')], hasMore: false));

    final container = containerFor();
    // An autoDispose provider with no listener is thrown away between awaits;
    // the socket has to still be subscribed when the message arrives.
    container.listen(threadProvider('c1'), (_, _) {});
    await container.read(threadProvider('c1').future);

    socket.add(message('m2'));
    // chat-service broadcasts to everyone subscribed, the sender included, so
    // the same message can arrive twice.
    socket.add(message('m2'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(threadProvider('c1')).value!.map((m) => m.id),
        ['m2', 'm1']);
  });

  test('sending shows the server copy without waiting for the socket',
      () async {
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => const MessagePage(items: [], hasMore: false));
    when(() => repository.listConversations())
        .thenAnswer((_) async => [conversation()]);
    when(() => repository.sendMessage('c1', 'hello'))
        .thenAnswer((_) async => message('m9', sender: '1001'));

    final container = containerFor();
    await container.read(threadProvider('c1').future);
    await container.read(threadProvider('c1').notifier).send('hello');

    expect(container.read(threadProvider('c1')).value!.single.id, 'm9');
  });

  test('loadMore appends older history and stops when hasMore is false',
      () async {
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => MessagePage(
              items: [message('m2')],
              hasMore: true,
              nextCursor: 'cur',
            ));
    when(() => repository.listMessages('c1',
            cursor: 'cur', size: any(named: 'size')))
        .thenAnswer((_) async =>
            MessagePage(items: [message('m1')], hasMore: false));

    final container = containerFor();
    await container.read(threadProvider('c1').future);
    final notifier = container.read(threadProvider('c1').notifier);
    await notifier.loadMore();

    expect(container.read(threadProvider('c1')).value!.map((m) => m.id),
        ['m2', 'm1']);

    // hasMore was false on that page, so the guard is closed: scrolling on
    // must not ask for the same cursor again.
    await notifier.loadMore();
    verify(() => repository.listMessages('c1',
        cursor: 'cur', size: any(named: 'size'))).called(1);
  });

  group('the conversation list over the socket', () {
    late StreamController<ChatInboxEvent> inbox;

    setUp(() {
      inbox = StreamController<ChatInboxEvent>.broadcast();
      addTearDown(inbox.close);
      when(() => repository.inboxEvents()).thenAnswer((_) => inbox.stream);
    });

    ChatInboxEvent arrived(MessageModel m) => ChatInboxEvent(
          type: ChatEventType.message,
          conversationId: m.conversationId,
          message: m,
        );

    MessageModel inThread(String conversationId, String id,
            {String sender = '2002'}) =>
        MessageModel(
          id: id,
          conversationId: conversationId,
          senderId: sender,
          content: 'message $id',
          sentAt: DateTime(2026, 9, 2),
        );

    Future<ProviderContainer> listening() async {
      final container = containerFor();
      container.listen(conversationsProvider, (_, _) {});
      await container.read(conversationsProvider.future);
      return container;
    }

    test('a new message moves its thread to the top, unread', () async {
      when(() => repository.listConversations()).thenAnswer(
          (_) async => [conversation(id: 'c1'), conversation(id: 'c2')]);
      final container = await listening();

      inbox.add(arrived(inThread('c2', 'm5')));
      await Future<void>.delayed(Duration.zero);

      final rows = container.read(conversationsProvider).value!;
      expect(rows.map((c) => c.id), ['c2', 'c1']);
      expect(rows.first.lastMessageContent, 'message m5');
      expect(rows.first.hasUnread, isTrue);
      expect(container.read(unreadConversationsProvider), 1);
      // Updated in place, not refetched.
      verify(() => repository.listConversations()).called(1);
    });

    test('the caller\'s own message does not mark the thread unread',
        () async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [conversation(hasUnread: true)]);
      final container = await listening();

      // chat-service sends nothing back to the sender's queue for text, so
      // the thread hands the list its own send.
      container
          .read(conversationsProvider.notifier)
          .sent(inThread('c1', 'm6', sender: '1001'));

      expect(container.read(conversationsProvider).value!.single.hasUnread,
          isFalse);
    });

    test('a message in a thread that is open stays read', () async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [conversation()]);
      when(() => repository.listMessages('c1', size: any(named: 'size')))
          .thenAnswer((_) async =>
              const MessagePage(items: [], hasMore: false));
      final container = await listening();
      container.listen(threadProvider('c1'), (_, _) {});
      await container.read(threadProvider('c1').future);

      inbox.add(arrived(inThread('c1', 'm7')));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(conversationsProvider).value!.single.hasUnread,
          isFalse);
    });

    test('a thread that changed on the server is fetched again', () async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [conversation()]);
      final container = await listening();

      inbox.add(const ChatInboxEvent(
          type: ChatEventType.conversation, conversationId: 'c1'));
      await Future<void>.delayed(Duration.zero);
      await container.read(conversationsProvider.future);

      verify(() => repository.listConversations()).called(2);
    });

    test('typing and receipts leave the list alone', () async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [conversation()]);
      final container = await listening();

      inbox.add(const ChatInboxEvent(
          type: ChatEventType.other, conversationId: 'c1'));
      await Future<void>.delayed(Duration.zero);
      await container.read(conversationsProvider.future);

      verify(() => repository.listConversations()).called(1);
    });

    test('a thread the list has never seen is fetched', () async {
      var calls = 0;
      when(() => repository.listConversations()).thenAnswer((_) async {
        calls++;
        return [
          conversation(id: 'c1'),
          if (calls > 1) conversation(id: 'c3', hasUnread: true),
        ];
      });
      final container = await listening();

      // Somebody writing for the first time: the message alone does not say
      // who they are, so the whole list comes back from the server.
      inbox.add(arrived(inThread('c3', 'm1')));
      await Future<void>.delayed(Duration.zero);
      await container.read(conversationsProvider.future);

      expect(container.read(conversationsProvider).value!.map((c) => c.id),
          containsAll(['c1', 'c3']));
    });
  });

  test('a message from the other person in an open thread is marked read',
      () async {
    final socket = StreamController<MessageModel>.broadcast();
    addTearDown(socket.close);
    when(() => repository.liveMessages('c1'))
        .thenAnswer((_) => socket.stream);
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => const MessagePage(items: [], hasMore: false));

    final container = containerFor();
    container.listen(threadProvider('c1'), (_, _) {});
    await container.read(threadProvider('c1').future);
    clearInteractions(repository);

    socket.add(message('m3'));
    socket.add(message('m4', sender: '1001'));
    await Future<void>.delayed(Duration.zero);

    // Once, for the other person's message; the caller's own needs nothing.
    verify(() => repository.markRead('c1')).called(1);
  });
}
