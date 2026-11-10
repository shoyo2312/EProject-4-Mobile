import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';

/// A tag in a comment is plain text: `@handle`, at the start or after a
/// space. notification-service reads the same pattern
/// (`CommentMentions.PATTERN`) to tell the people tagged, so what is drawn as
/// a tag here is exactly what the server treats as one. A trailing full stop
/// is punctuation, not part of the handle.
final mentionPattern = RegExp(
  r'(?<![^\s])@([\p{L}\p{N}_.]*[\p{L}\p{N}_])',
  unicode: true,
);

/// How many people one comment may tag; the server stops reading after 10.
const maxMentions = 10;

/// How many suggestions the composer shows at once.
const mentionSuggestionLimit = 6;

/// The `@word` being typed at [cursor]: where its `@` is and what follows it
/// so far (possibly nothing). Null when the cursor is not in one.
({int start, String query})? mentionTokenAt(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  if (at < 0) return null;
  if (at > 0 && !RegExp(r'\s').hasMatch(before[at - 1])) return null;
  final query = before.substring(at + 1);
  if (!RegExp(r'^[\p{L}\p{N}_.]*$', unicode: true).hasMatch(query)) {
    return null;
  }
  return (start: at, query: query);
}

/// What goes after the `@` for [profile]: their handle, or for an account
/// made before handles, the display name without spaces (the web does the
/// same).
String? mentionHandle(UserProfileModel profile) {
  final username = profile.username?.trim();
  if (username != null && username.isNotEmpty) return username;
  final squashed = profile.displayName.replaceAll(RegExp(r'\s+'), '');
  return mentionPattern.hasMatch('@$squashed') ? squashed : null;
}

/// [text] with the token at [start] (up to [cursor]) replaced by `@handle `,
/// and where the cursor goes after it.
({String text, int cursor}) applyMention(
  String text,
  int start,
  int cursor,
  String handle,
) {
  final insert = '@$handle ';
  final rest = text.substring(cursor);
  // The space is already there when the tag went in mid-sentence.
  final tail = rest.startsWith(' ') ? rest.substring(1) : rest;
  final next = '${text.substring(0, start)}$insert$tail';
  return (text: next, cursor: start + insert.length);
}

/// The handles tagged in [text], lowercased, first-seen order, no repeats.
List<String> mentionedHandles(String text) {
  final seen = <String>{};
  return [
    for (final m in mentionPattern.allMatches(text))
      if (seen.add(m.group(1)!.toLowerCase())) m.group(1)!.toLowerCase(),
  ];
}

/// [text] cut into plain runs and tags, in order, for drawing.
List<({String text, String? handle})> splitMentions(String text) {
  final runs = <({String text, String? handle})>[];
  var at = 0;
  for (final m in mentionPattern.allMatches(text)) {
    if (m.start > at) {
      runs.add((text: text.substring(at, m.start), handle: null));
    }
    runs.add((text: m.group(0)!, handle: m.group(1)));
    at = m.end;
  }
  if (at < text.length) runs.add((text: text.substring(at), handle: null));
  return runs;
}

/// The people in [friends] that [query] (what follows the `@`) matches, by
/// handle or by name, best matches first.
List<UserProfileModel> matchMentions(
  List<UserProfileModel> friends,
  String query, {
  int limit = mentionSuggestionLimit,
}) {
  final q = query.toLowerCase();
  int rank(UserProfileModel p) {
    final handle = (mentionHandle(p) ?? '').toLowerCase();
    final name = p.displayName.toLowerCase();
    if (q.isEmpty) return 0;
    if (handle.startsWith(q)) return 0;
    if (name.startsWith(q)) return 1;
    if (handle.contains(q)) return 2;
    if (name.contains(q)) return 3;
    return -1;
  }

  final ranked = [
    for (final p in friends)
      if (mentionHandle(p) != null && rank(p) >= 0) (p, rank(p)),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final r in ranked.take(limit)) r.$1];
}
