import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
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

/// The smallest thing each check accepts: the first bytes of a JPEG.
final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);

/// A real 1×1 PNG, for the screens that actually draw the picture.
final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

const sticker = StickerModel(
  stickerId: 'fire',
  name: 'Fire',
  url: 'http://localhost:9000/video-media/stickers/fluent-3d/v1/fire.png',
  width: 256,
  height: 256,
);

MessageModel mine(String id, {MessageType type = MessageType.text}) =>
    MessageModel(
      id: id,
      conversationId: 'c1',
      senderId: '1001',
      content: '',
      sentAt: DateTime(2026, 11, 1),
      type: type,
    );

void main() {
  late MockChatRepository repository;
  late MockUserRepository users;

  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockChatRepository();
    users = MockUserRepository();
    when(() => users.getProfiles(any()))
        .thenAnswer((_) async => <String, UserProfileModel>{});
    when(() => repository.markRead(any())).thenAnswer((_) async {});
    when(() => repository.liveMessages(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.inboxEvents())
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.listConversations()).thenAnswer((_) async => []);
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => const MessagePage(items: [], hasMore: false));
    when(() => repository.rememberImage(any(), any())).thenReturn(null);
  });

  List<Override> overrides() => [
        authStateProvider.overrideWith(_SignedIn.new),
        chatRepositoryProvider.overrideWithValue(repository),
        userRepositoryProvider.overrideWithValue(users),
      ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides());
    addTearDown(c.dispose);
    return c;
  }

  group('reading media messages', () {
    test('a sticker message carries its sticker', () {
      final m = messageFromServer({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 2002,
        'content': null,
        'sentAt': '2026-11-01T00:00:00Z',
        'type': 'STICKER',
        'stickerId': 'fire',
        'sticker': sticker.toJson(),
      });
      expect(m.type, MessageType.sticker);
      expect(m.sticker!.url, sticker.url);
    });

    test('a picture keeps an empty caption and previews as Photo', () {
      final m = messageFromServer({
        'id': 'm2',
        'conversationId': 'c1',
        'senderId': 2002,
        'content': null,
        'sentAt': '2026-11-01T00:00:00Z',
        'type': 'IMAGE',
        'image': {
          'imageId': 'i1',
          'url': '/api/v1/conversations/c1/images/i1',
          'mime': 'image/jpeg',
          'width': 800,
          'height': 600,
          'size': 1234,
        },
      });
      expect(m.type, MessageType.image);
      expect(m.content, '');
      expect(m.image!.width, 800);
      expect(m.previewText, 'Photo');
    });

    test('a picture in the conversation list previews as Photo, no caption',
        () {
      final c = conversationFromServer({
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-08-01T00:00:00Z',
        'lastMessageType': 'IMAGE',
        'lastMessageContent': null,
      });
      expect(c.lastMessageContent, 'Photo');
    });

    test('a type this build does not know still parses', () {
      final m = messageFromServer({
        'id': 'm3',
        'conversationId': 'c1',
        'senderId': 2002,
        'content': 'hi',
        'sentAt': '2026-11-01T00:00:00Z',
        'type': 'HOLOGRAM',
      });
      expect(m.type, MessageType.unknown);
      expect(m.content, 'hi');
    });
  });

  group('checking a picture before it goes up', () {
    test('JPEG, PNG and GIF pass', () {
      expect(OutgoingImages.problemWith(jpeg), isNull);
      expect(
          OutgoingImages.problemWith(
              Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0])),
          isNull);
      expect(
          OutgoingImages.problemWith(
              Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])),
          isNull);
    });

    test('WebP and HEIC are refused before the upload', () {
      // RIFF....WEBP
      final webp = Uint8List.fromList(
          [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]);
      expect(OutgoingImages.problemWith(webp), contains('JPEG, PNG and GIF'));
    });

    test('over 5 MB is refused before the upload', () {
      final big = Uint8List(OutgoingImages.maxBytes + 1)
        ..setAll(0, [0xFF, 0xD8, 0xFF]);
      expect(OutgoingImages.problemWith(big), contains('5 MB'));
    });
  });

  test('a sticker is sent as its own message and lands in the thread',
      () async {
    when(() => repository.sendSticker('c1', 'fire',
            clientRequestId: any(named: 'clientRequestId')))
        .thenAnswer((_) async => mine('m9', type: MessageType.sticker));
    final c = container();
    c.listen(threadProvider('c1'), (_, _) {});
    await c.read(threadProvider('c1').future);

    await c.read(threadProvider('c1').notifier).sendSticker(sticker);

    expect(c.read(threadProvider('c1')).value!.single.id, 'm9');
  });

  group('sending a picture', () {
    test('uploads, claims it in a message, and leaves the queue', () async {
      when(() => repository.uploadImage('c1',
              bytes: any(named: 'bytes'),
              filename: 'shot.jpg',
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const ChatImageModel(
              imageId: 'i1', url: '/api/v1/conversations/c1/images/i1'));
      when(() => repository.sendImage('c1', 'i1',
              caption: 'look',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) async => mine('m5', type: MessageType.image));
      final c = container();
      c.listen(threadProvider('c1'), (_, _) {});
      c.listen(outgoingImagesProvider('c1'), (_, _) {});
      await c.read(threadProvider('c1').future);

      await c
          .read(outgoingImagesProvider('c1').notifier)
          .send(jpeg, filename: 'shot.jpg', caption: 'look');

      expect(c.read(outgoingImagesProvider('c1')), isEmpty);
      expect(c.read(threadProvider('c1')).value!.single.id, 'm5');
      // Its own bytes are kept, so the sender's picture is not downloaded
      // straight back.
      verify(() => repository.rememberImage('i1', jpeg)).called(1);
    });

    test('a refusal stays on screen in words, and Retry sends it', () async {
      var attempts = 0;
      when(() => repository.uploadImage('c1',
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              onProgress: any(named: 'onProgress'))).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const ServerException(400, 'raw',
              code: 'MESSAGE_REQUEST_NOT_ACCEPTED');
        }
        return const ChatImageModel(imageId: 'i2', url: '/x');
      });
      String? usedRequestId;
      when(() => repository.sendImage('c1', 'i2',
              caption: any(named: 'caption'),
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((invocation) async {
        usedRequestId =
            invocation.namedArguments[#clientRequestId] as String;
        return mine('m6', type: MessageType.image);
      });
      final c = container();
      c.listen(threadProvider('c1'), (_, _) {});
      c.listen(outgoingImagesProvider('c1'), (_, _) {});
      await c.read(threadProvider('c1').future);
      final notifier = c.read(outgoingImagesProvider('c1').notifier);

      await notifier.send(jpeg, filename: 'a.jpg');
      final failed = c.read(outgoingImagesProvider('c1')).single;
      expect(failed.error, contains('accept your message request'));

      await notifier.retry(failed.localId);

      expect(c.read(outgoingImagesProvider('c1')), isEmpty);
      // The retry reuses the id, so a send that did reach the server the
      // first time answers with that message instead of a second one.
      expect(usedRequestId, failed.localId);
    });
  });

  testWidgets('camera → preview → send queues the picture with its caption',
      (tester) async {
    final upload = Completer<ChatImageModel>();
    when(() => repository.uploadImage('c1',
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        onProgress: any(named: 'onProgress'))).thenAnswer((_) => upload.future);
    ImageSource? askedFor;

    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        home: ChatThreadScreen(
          conversationId: 'c1',
          pickPhoto: (source) async {
            askedFor = source;
            return XFile.fromData(png, name: 'shot.png');
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_attach_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_attach_camera')));
    await tester.pumpAndSettle();

    expect(askedFor, ImageSource.camera);
    // A shot from the camera can be taken again from the preview.
    expect(find.byKey(const Key('photo_preview_retake')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('photo_preview_caption')), 'sunset');
    await tester.tap(find.byKey(const Key('photo_preview_send')));
    await tester.pump();
    await tester.pump();

    final queued = ProviderScope.containerOf(
            tester.element(find.byType(ChatThreadScreen)))
        .read(outgoingImagesProvider('c1'));
    expect(queued.single.caption, 'sunset');
    expect(find.byKey(Key('outgoing_photo_${queued.single.localId}')),
        findsOneWidget);

    // Let the queued send finish so nothing is left pending.
    upload.completeError(const NetworkException());
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsOneWidget);
  });
}
