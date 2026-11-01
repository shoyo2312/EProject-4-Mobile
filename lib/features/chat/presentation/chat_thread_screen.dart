import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/photo_preview_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/chat_image.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/sticker_sheet.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Picks a picture from the camera or the gallery. Swapped in tests, where
/// there is neither.
typedef PhotoPicker = Future<XFile?> Function(ImageSource source);

/// Scaled and re-encoded on the device before it is sent: a phone camera's
/// 12 MP original is well past the server's 5 MB, and nothing in a chat needs
/// more than 2048 px a side.
Future<XFile?> pickChatPhoto(ImageSource source) => ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

/// One conversation: history above, composer below, live updates in between.
///
/// The list is reversed — index 0 is the newest message and sits at the
/// bottom, which is both how the server sorts a page and how a chat is read.
/// Pictures still on their way out sit below everything the server has.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.pickPhoto = pickChatPhoto,
  });

  final String conversationId;
  final PhotoPicker pickPhoto;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref
          .read(threadProvider(widget.conversationId).notifier)
          .send(text);
    } on AppException catch (e) {
      if (!mounted) return;
      // Put the text back rather than losing what was typed.
      _controller.text = text;
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickSticker() async {
    final sticker = await showStickerSheet(context);
    if (sticker == null || !mounted) return;
    try {
      await ref
          .read(threadProvider(widget.conversationId).notifier)
          .sendSticker(sticker);
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _attach() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('chat_attach_camera'),
              leading: const Icon(Icons.photo_camera_outlined, color: NowaColors.text),
              title: Text('Take a photo', style: work(size: 14)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              key: const Key('chat_attach_gallery'),
              leading: const Icon(Icons.photo_library_outlined, color: NowaColors.text),
              title: Text('Choose from library', style: work(size: 14)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _sendPhotoFrom(source);
  }

  /// Pick, preview, send. A shot from the camera can be retaken from the
  /// preview, which loops back here.
  Future<void> _sendPhotoFrom(ImageSource source) async {
    while (mounted) {
      final XFile? file;
      try {
        file = await widget.pickPhoto(source);
      } catch (_) {
        // Permission refused, or no camera: the picker throws rather than
        // answering null.
        _toast(source == ImageSource.camera
            ? 'Could not open the camera'
            : 'Could not open your photos');
        return;
      }
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final problem = OutgoingImages.problemWith(bytes);
      if (problem != null) {
        _toast(problem);
        return;
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push(
        MaterialPageRoute<PhotoPreviewResult>(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewScreen(
            bytes: bytes,
            canRetake: source == ImageSource.camera,
          ),
        ),
      );
      switch (result) {
        case SendPhoto(:final caption):
          // Not awaited: the row shows its own progress and failure.
          ref
              .read(outgoingImagesProvider(widget.conversationId).notifier)
              .send(bytes, filename: file.name, caption: caption);
          return;
        case RetakePhoto():
          continue;
        case null:
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final thread = ref.watch(threadProvider(widget.conversationId));
    final outgoing = ref.watch(outgoingImagesProvider(widget.conversationId));
    final maxWidth = MediaQuery.of(context).size.width * 0.62;

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(title: _title(me?.id)),
      body: Column(
        children: [
          Expanded(
            child: thread.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(threadProvider(widget.conversationId)),
              ),
              data: (messages) => NotificationListener<ScrollNotification>(
                // Reversed list: "the end" is older history, at the top.
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.metrics.extentAfter < 400) {
                    ref
                        .read(threadProvider(widget.conversationId).notifier)
                        .loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: outgoing.length + messages.length,
                  itemBuilder: (_, i) {
                    if (i < outgoing.length) {
                      // Newest pending at the bottom, like everything else.
                      return _OutgoingPhoto(
                        item: outgoing[outgoing.length - 1 - i],
                        conversationId: widget.conversationId,
                        maxWidth: maxWidth,
                      );
                    }
                    final message = messages[i - outgoing.length];
                    return _Bubble(
                      message: message,
                      mine: message.senderId == me?.id,
                      maxWidth: maxWidth,
                    );
                  },
                ),
              ),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  /// The other participant's name, once the conversation and their profile are
  /// both known. Until then the header says "Messages" rather than flashing an
  /// id at the reader.
  String _title(String? me) {
    if (me == null) return 'Messages';
    final conversation = ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (conversation == null) return 'Messages';
    final otherId = conversation.otherParticipant(me);
    return ref.watch(profileCacheProvider)[otherId]?.displayName ?? 'Messages';
  }

  Widget _composer() {
    final dim = NowaColors.text.withValues(alpha: 0.7);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NowaColors.hairline)),
        ),
        child: Row(
          children: [
            IconButton(
              key: const Key('chat_attach_button'),
              tooltip: 'Photo',
              onPressed: _attach,
              icon: Icon(Icons.add_circle_outline, size: 22, color: dim),
            ),
            Expanded(
              child: TextField(
                key: const Key('chat_composer_field'),
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                // The server caps a message at 2000 characters; stopping here
                // beats a 400 after the fact.
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: work(size: 14, height: 1.3),
                cursorColor: NowaColors.accent,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Message',
                  hintStyle: work(
                    size: 14,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('chat_sticker_button'),
              tooltip: 'Stickers',
              onPressed: _pickSticker,
              icon: Icon(Icons.emoji_emotions_outlined, size: 22, color: dim),
            ),
            GestureDetector(
              key: const Key('chat_send_button'),
              behavior: HitTestBehavior.opaque,
              onTap: _send,
              child: Icon(
                Icons.arrow_upward,
                size: 20,
                color: _sending
                    ? NowaColors.accent.withValues(alpha: 0.4)
                    : NowaColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.maxWidth,
  });

  final MessageModel message;
  final bool mine;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final time = Text(
      timeAgo(message.sentAt),
      style: work(
        size: 10,
        height: 1,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final sticker = message.sticker;
    if (sticker != null && !message.recalled) {
      return _aligned(
        Column(
          crossAxisAlignment: align,
          children: [
            StickerImage(sticker: sticker, size: 120),
            const SizedBox(height: 3),
            time,
          ],
        ),
      );
    }

    final image = message.image;
    if (image != null && !message.recalled) {
      return _aligned(
        Column(
          crossAxisAlignment: align,
          children: [
            ChatImage(image: image, maxWidth: maxWidth),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              _textBubble(context, Text(message.content, style: work(size: 13.5, height: 1.35)), null),
            ],
            const SizedBox(height: 3),
            time,
          ],
        ),
      );
    }

    final text = Text(
      message.content,
      style: message.recalled
          ? work(size: 13.5, height: 1.35, color: NowaColors.text.withValues(alpha: 0.55))
              .copyWith(fontStyle: FontStyle.italic)
          : work(size: 13.5, height: 1.35),
    );
    return _aligned(_textBubble(context, text, time));
  }

  Widget _aligned(Widget child) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
      );

  Widget _textBubble(BuildContext context, Widget text, Widget? time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: mine && !message.recalled ? NowaColors.accent : NowaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          if (time != null) ...[const SizedBox(height: 3), time],
        ],
      ),
    );
  }
}

/// A picture the caller is sending: drawn from the bytes on the device, with
/// a progress ring while it goes up, or Retry / Remove if it failed.
class _OutgoingPhoto extends ConsumerWidget {
  const _OutgoingPhoto({
    required this.item,
    required this.conversationId,
    required this.maxWidth,
  });

  final OutgoingImage item;
  final String conversationId;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(outgoingImagesProvider(conversationId).notifier);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              key: Key('outgoing_photo_${item.localId}'),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxWidth * 1.3,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: item.failed ? 0.4 : 0.7,
                      child: Image.memory(item.bytes, fit: BoxFit.cover),
                    ),
                    if (!item.failed)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: item.progress > 0 && item.progress < 1
                              ? item.progress
                              : null,
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (item.failed) ...[
              const SizedBox(height: 4),
              Text(
                item.error!,
                style: work(size: 11.5, color: NowaColors.danger),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: Key('outgoing_photo_remove_${item.localId}'),
                    onPressed: () => notifier.remove(item.localId),
                    child: Text('Remove', style: work(size: 12)),
                  ),
                  TextButton(
                    key: Key('outgoing_photo_retry_${item.localId}'),
                    onPressed: () => notifier.retry(item.localId),
                    child: Text(
                      'Retry',
                      style: work(size: 12, color: NowaColors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
