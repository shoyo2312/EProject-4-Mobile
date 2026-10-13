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

ConversationModel conversation({bool hasUnread = false}) => ConversationModel(
      id: 'c1',
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
}
