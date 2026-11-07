// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSocketHash() => r'd24db1e25799ccd303c8013727cd92c4e8887822';

/// The one chat socket. Opens on the first live stream and closes with the
/// last, so a signed-out app holds nothing open.
///
/// Copied from [chatSocket].
@ProviderFor(chatSocket)
final chatSocketProvider = Provider<ChatSocket>.internal(
  chatSocket,
  name: r'chatSocketProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatSocketHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatSocketRef = ProviderRef<ChatSocket>;
String _$chatRepositoryHash() => r'd38eb0620dbbe938f2cd05b06b16c71613bd8dc7';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = Provider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = ProviderRef<ChatRepository>;
String _$requestCountsHash() => r'9604e919752f67a5dd4346a1b38a4f36ddedc1e2';

/// See also [requestCounts].
@ProviderFor(requestCounts)
final requestCountsProvider = AutoDisposeProvider<RequestCounts>.internal(
  requestCounts,
  name: r'requestCountsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestCountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RequestCountsRef = AutoDisposeProviderRef<RequestCounts>;
String _$stickerPacksHash() => r'33071afeed94a5059c937c986dc1dead4611a2e5';

/// The sticker catalog, fetched once per session — it changes with a server
/// release, not while the app is open.
///
/// Copied from [stickerPacks].
@ProviderFor(stickerPacks)
final stickerPacksProvider = FutureProvider<List<StickerPack>>.internal(
  stickerPacks,
  name: r'stickerPacksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stickerPacksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StickerPacksRef = FutureProviderRef<List<StickerPack>>;
String _$chatImageBytesHash() => r'45218dafe05594ce9aa7c34894c175d4f0f7b535';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
@ProviderFor(chatImageBytes)
const chatImageBytesProvider = ChatImageBytesFamily();

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
class ChatImageBytesFamily extends Family<AsyncValue<Uint8List>> {
  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  const ChatImageBytesFamily();

  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  ChatImageBytesProvider call(ChatImageModel image) {
    return ChatImageBytesProvider(image);
  }

  @override
  ChatImageBytesProvider getProviderOverride(
    covariant ChatImageBytesProvider provider,
  ) {
    return call(provider.image);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatImageBytesProvider';
}

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
class ChatImageBytesProvider extends AutoDisposeFutureProvider<Uint8List> {
  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  ChatImageBytesProvider(ChatImageModel image)
    : this._internal(
        (ref) => chatImageBytes(ref as ChatImageBytesRef, image),
        from: chatImageBytesProvider,
        name: r'chatImageBytesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatImageBytesHash,
        dependencies: ChatImageBytesFamily._dependencies,
        allTransitiveDependencies:
            ChatImageBytesFamily._allTransitiveDependencies,
        image: image,
      );

  ChatImageBytesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.image,
  }) : super.internal();

  final ChatImageModel image;

  @override
  Override overrideWith(
    FutureOr<Uint8List> Function(ChatImageBytesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatImageBytesProvider._internal(
        (ref) => create(ref as ChatImageBytesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        image: image,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Uint8List> createElement() {
    return _ChatImageBytesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatImageBytesProvider && other.image == image;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, image.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatImageBytesRef on AutoDisposeFutureProviderRef<Uint8List> {
  /// The parameter `image` of this provider.
  ChatImageModel get image;
}

class _ChatImageBytesProviderElement
    extends AutoDisposeFutureProviderElement<Uint8List>
    with ChatImageBytesRef {
  _ChatImageBytesProviderElement(super.provider);

  @override
  ChatImageModel get image => (origin as ChatImageBytesProvider).image;
}

String _$unreadConversationsHash() =>
    r'fdc98fbe8ae1f9ccdeab5fdb59c7b4814baac7d9';

/// Threads with something the user has not read — the dot on the Inbox tab
/// and its Messages shortcut — plus message requests not opened yet, so a
/// request is noticed from anywhere. A muted thread is left out: its
/// messages still arrive and its row still turns bold, but it does not
/// nudge. Watching it keeps both lists, and so the inbox socket, alive while
/// the app is up.
///
/// Copied from [unreadConversations].
@ProviderFor(unreadConversations)
final unreadConversationsProvider = AutoDisposeProvider<int>.internal(
  unreadConversations,
  name: r'unreadConversationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadConversationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadConversationsRef = AutoDisposeProviderRef<int>;
String _$conversationsHash() => r'bd792fdbda06198c61570e6ce23da8ea4140a19b';

/// The thread list, most recently active first, kept current over the socket.
///
/// Signed out there is nothing to list — every endpoint here needs a token —
/// so a guest gets an empty list rather than a 401 behind the screen.
///
/// Copied from [Conversations].
@ProviderFor(Conversations)
final conversationsProvider =
    AutoDisposeAsyncNotifierProvider<
      Conversations,
      List<ConversationModel>
    >.internal(
      Conversations.new,
      name: r'conversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Conversations = AutoDisposeAsyncNotifier<List<ConversationModel>>;
String _$messageRequestsHash() => r'eaf60d8852bcf84cd191a347a5038982d1b0e17a';

/// Message requests waiting on the caller: threads opened by people they do
/// not follow back, each holding the one message its sender was allowed. Not
/// part of [Conversations] until accepted; opening one reads it but does not
/// answer it.
///
/// Copied from [MessageRequests].
@ProviderFor(MessageRequests)
final messageRequestsProvider =
    AutoDisposeAsyncNotifierProvider<
      MessageRequests,
      List<ConversationModel>
    >.internal(
      MessageRequests.new,
      name: r'messageRequestsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageRequestsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageRequests = AutoDisposeAsyncNotifier<List<ConversationModel>>;
String _$conversationDetailHash() =>
    r'4b1717932d4d211f1623c0e55b51d04e364998f6';

abstract class _$ConversationDetail
    extends BuildlessAutoDisposeAsyncNotifier<ConversationModel?> {
  late final String conversationId;

  FutureOr<ConversationModel?> build(String conversationId);
}

/// One conversation as the caller sees it, for the thread screen: its header,
/// its menu and what stands where the composer goes. Taken from the inbox or
/// the request box when either has it, so the three agree; fetched otherwise
/// (a request the caller deleted is in neither).
///
/// Copied from [ConversationDetail].
@ProviderFor(ConversationDetail)
const conversationDetailProvider = ConversationDetailFamily();

/// One conversation as the caller sees it, for the thread screen: its header,
/// its menu and what stands where the composer goes. Taken from the inbox or
/// the request box when either has it, so the three agree; fetched otherwise
/// (a request the caller deleted is in neither).
///
/// Copied from [ConversationDetail].
class ConversationDetailFamily extends Family<AsyncValue<ConversationModel?>> {
  /// One conversation as the caller sees it, for the thread screen: its header,
  /// its menu and what stands where the composer goes. Taken from the inbox or
  /// the request box when either has it, so the three agree; fetched otherwise
  /// (a request the caller deleted is in neither).
  ///
  /// Copied from [ConversationDetail].
  const ConversationDetailFamily();

  /// One conversation as the caller sees it, for the thread screen: its header,
  /// its menu and what stands where the composer goes. Taken from the inbox or
  /// the request box when either has it, so the three agree; fetched otherwise
  /// (a request the caller deleted is in neither).
  ///
  /// Copied from [ConversationDetail].
  ConversationDetailProvider call(String conversationId) {
    return ConversationDetailProvider(conversationId);
  }

  @override
  ConversationDetailProvider getProviderOverride(
    covariant ConversationDetailProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationDetailProvider';
}

/// One conversation as the caller sees it, for the thread screen: its header,
/// its menu and what stands where the composer goes. Taken from the inbox or
/// the request box when either has it, so the three agree; fetched otherwise
/// (a request the caller deleted is in neither).
///
/// Copied from [ConversationDetail].
class ConversationDetailProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ConversationDetail,
          ConversationModel?
        > {
  /// One conversation as the caller sees it, for the thread screen: its header,
  /// its menu and what stands where the composer goes. Taken from the inbox or
  /// the request box when either has it, so the three agree; fetched otherwise
  /// (a request the caller deleted is in neither).
  ///
  /// Copied from [ConversationDetail].
  ConversationDetailProvider(String conversationId)
    : this._internal(
        () => ConversationDetail()..conversationId = conversationId,
        from: conversationDetailProvider,
        name: r'conversationDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationDetailHash,
        dependencies: ConversationDetailFamily._dependencies,
        allTransitiveDependencies:
            ConversationDetailFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<ConversationModel?> runNotifierBuild(
    covariant ConversationDetail notifier,
  ) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(ConversationDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConversationDetailProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ConversationDetail,
    ConversationModel?
  >
  createElement() {
    return _ConversationDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationDetailProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationDetailRef
    on AutoDisposeAsyncNotifierProviderRef<ConversationModel?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationDetailProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ConversationDetail,
          ConversationModel?
        >
    with ConversationDetailRef {
  _ConversationDetailProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationDetailProvider).conversationId;
}

String _$threadHash() => r'75ed21792de94ea6090e7fd0e8613c1d0572f9f9';

abstract class _$Thread
    extends BuildlessAutoDisposeAsyncNotifier<List<MessageModel>> {
  late final String conversationId;

  FutureOr<List<MessageModel>> build(String conversationId);
}

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
@ProviderFor(Thread)
const threadProvider = ThreadFamily();

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
class ThreadFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  const ThreadFamily();

  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  ThreadProvider call(String conversationId) {
    return ThreadProvider(conversationId);
  }

  @override
  ThreadProvider getProviderOverride(covariant ThreadProvider provider) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'threadProvider';
}

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
class ThreadProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Thread, List<MessageModel>> {
  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  ThreadProvider(String conversationId)
    : this._internal(
        () => Thread()..conversationId = conversationId,
        from: threadProvider,
        name: r'threadProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$threadHash,
        dependencies: ThreadFamily._dependencies,
        allTransitiveDependencies: ThreadFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ThreadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<List<MessageModel>> runNotifierBuild(covariant Thread notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(Thread Function() create) {
    return ProviderOverride(
      origin: this,
      override: ThreadProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Thread, List<MessageModel>>
  createElement() {
    return _ThreadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadProvider && other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ThreadRef on AutoDisposeAsyncNotifierProviderRef<List<MessageModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ThreadProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Thread, List<MessageModel>>
    with ThreadRef {
  _ThreadProviderElement(super.provider);

  @override
  String get conversationId => (origin as ThreadProvider).conversationId;
}

String _$peerReceiptHash() => r'f1bd71172e86b4df1b9967dde5083be23e54e826';

abstract class _$PeerReceipt
    extends BuildlessAutoDisposeAsyncNotifier<ReceiptView?> {
  late final String conversationId;

  FutureOr<ReceiptView?> build(String conversationId);
}

/// How far the other participant has got in one thread — what turns the
/// caller's messages into Delivered and Seen. Fetched once, then moved along
/// by the RECEIPT frames the server sends as they receive and read.
///
/// Copied from [PeerReceipt].
@ProviderFor(PeerReceipt)
const peerReceiptProvider = PeerReceiptFamily();

/// How far the other participant has got in one thread — what turns the
/// caller's messages into Delivered and Seen. Fetched once, then moved along
/// by the RECEIPT frames the server sends as they receive and read.
///
/// Copied from [PeerReceipt].
class PeerReceiptFamily extends Family<AsyncValue<ReceiptView?>> {
  /// How far the other participant has got in one thread — what turns the
  /// caller's messages into Delivered and Seen. Fetched once, then moved along
  /// by the RECEIPT frames the server sends as they receive and read.
  ///
  /// Copied from [PeerReceipt].
  const PeerReceiptFamily();

  /// How far the other participant has got in one thread — what turns the
  /// caller's messages into Delivered and Seen. Fetched once, then moved along
  /// by the RECEIPT frames the server sends as they receive and read.
  ///
  /// Copied from [PeerReceipt].
  PeerReceiptProvider call(String conversationId) {
    return PeerReceiptProvider(conversationId);
  }

  @override
  PeerReceiptProvider getProviderOverride(
    covariant PeerReceiptProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'peerReceiptProvider';
}

/// How far the other participant has got in one thread — what turns the
/// caller's messages into Delivered and Seen. Fetched once, then moved along
/// by the RECEIPT frames the server sends as they receive and read.
///
/// Copied from [PeerReceipt].
class PeerReceiptProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PeerReceipt, ReceiptView?> {
  /// How far the other participant has got in one thread — what turns the
  /// caller's messages into Delivered and Seen. Fetched once, then moved along
  /// by the RECEIPT frames the server sends as they receive and read.
  ///
  /// Copied from [PeerReceipt].
  PeerReceiptProvider(String conversationId)
    : this._internal(
        () => PeerReceipt()..conversationId = conversationId,
        from: peerReceiptProvider,
        name: r'peerReceiptProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$peerReceiptHash,
        dependencies: PeerReceiptFamily._dependencies,
        allTransitiveDependencies: PeerReceiptFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  PeerReceiptProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<ReceiptView?> runNotifierBuild(covariant PeerReceipt notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(PeerReceipt Function() create) {
    return ProviderOverride(
      origin: this,
      override: PeerReceiptProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PeerReceipt, ReceiptView?>
  createElement() {
    return _PeerReceiptProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PeerReceiptProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PeerReceiptRef on AutoDisposeAsyncNotifierProviderRef<ReceiptView?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _PeerReceiptProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PeerReceipt, ReceiptView?>
    with PeerReceiptRef {
  _PeerReceiptProviderElement(super.provider);

  @override
  String get conversationId => (origin as PeerReceiptProvider).conversationId;
}

String _$outgoingImagesHash() => r'31e39b4dbf17633be2a56d1827f64f1cb2e150b1';

abstract class _$OutgoingImages
    extends BuildlessAutoDisposeNotifier<List<OutgoingImage>> {
  late final String conversationId;

  List<OutgoingImage> build(String conversationId);
}

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
@ProviderFor(OutgoingImages)
const outgoingImagesProvider = OutgoingImagesFamily();

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
class OutgoingImagesFamily extends Family<List<OutgoingImage>> {
  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  const OutgoingImagesFamily();

  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  OutgoingImagesProvider call(String conversationId) {
    return OutgoingImagesProvider(conversationId);
  }

  @override
  OutgoingImagesProvider getProviderOverride(
    covariant OutgoingImagesProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'outgoingImagesProvider';
}

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
class OutgoingImagesProvider
    extends
        AutoDisposeNotifierProviderImpl<OutgoingImages, List<OutgoingImage>> {
  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  OutgoingImagesProvider(String conversationId)
    : this._internal(
        () => OutgoingImages()..conversationId = conversationId,
        from: outgoingImagesProvider,
        name: r'outgoingImagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$outgoingImagesHash,
        dependencies: OutgoingImagesFamily._dependencies,
        allTransitiveDependencies:
            OutgoingImagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  OutgoingImagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  List<OutgoingImage> runNotifierBuild(covariant OutgoingImages notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(OutgoingImages Function() create) {
    return ProviderOverride(
      origin: this,
      override: OutgoingImagesProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<OutgoingImages, List<OutgoingImage>>
  createElement() {
    return _OutgoingImagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OutgoingImagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OutgoingImagesRef on AutoDisposeNotifierProviderRef<List<OutgoingImage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _OutgoingImagesProviderElement
    extends
        AutoDisposeNotifierProviderElement<OutgoingImages, List<OutgoingImage>>
    with OutgoingImagesRef {
  _OutgoingImagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as OutgoingImagesProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
