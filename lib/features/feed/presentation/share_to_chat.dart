import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

/// How many people the share sheet offers before anything is searched for.
const shareRecentLimit = 5;

/// How many people one send may go to (the web client's cap too).
const shareMaxRecipients = 10;

/// The conversations a video can be sent into from the share sheet, the
/// most recent message first — not the inbox's own order, where an old
/// pinned chat sits on top. Left out: chats a block closes, and requests
/// that cannot take a message right now (one already sent and waiting, or
/// one received and not accepted yet).
List<ConversationModel> shareableConversations(
  List<ConversationModel> rows,
  String me,
) {
  final seen = <String>{};
  final ordered = [...rows]
    ..sort((a, b) {
      final at = (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      );
      return at != 0 ? at : b.id.compareTo(a.id);
    });
  return [
    for (final c in ordered)
      if (c.messagingBlocked != true &&
          c.blockedByViewer != true &&
          c.sendPermission != SendPermission.requestSent &&
          c.sendPermission != SendPermission.awaitingAccept &&
          c.otherParticipant(me) != me &&
          seen.add(c.otherParticipant(me)))
        c,
  ];
}

/// Why one send of the video failed, in words.
String shareFailure(AppException e) =>
    switch (e is ServerException ? e.code : null) {
      'VIDEO_NOT_AVAILABLE' => 'This video isn\'t available',
      'VIDEO_NOT_SHAREABLE_TO_RECIPIENT' => 'They can\'t view this video',
      'VIDEO_CHECK_UNAVAILABLE' =>
        'Couldn\'t check the video. Try again in a moment',
      'MESSAGING_BLOCKED' => 'You can\'t message this account',
      'MESSAGE_REQUEST_LIMIT_REACHED' || 'MESSAGE_REQUEST_NOT_ACCEPTED' =>
        'You can send more once they accept your request',
      _ => e.message,
    };
