import 'package:shared_preferences/shared_preferences.dart';

// Sticker suggestions while typing, matched on the device the way the web
// client does: only the matched topic's id goes to the server, never the text.

/// Past this many words a message is a sentence, not a feeling.
const maxSuggestionWords = 3;
const maxSuggestionLength = 30;

/// Closing the suggestions this many times in a row, without sending one,
/// silences them in that conversation for [suggestionMute].
const suggestionDismissLimit = 2;
const suggestionMute = Duration(hours: 24);

/// One feeling or greeting from the server's table, ready to match.
class SuggestionTopic {
  SuggestionTopic({
    required this.id,
    required this.keywords,
    required this.patterns,
  });

  /// A pattern that does not compile is dropped, not fatal.
  factory SuggestionTopic.fromJson(Map<String, dynamic> json) =>
      SuggestionTopic(
        id: json['id'] as String,
        keywords: [
          for (final k in (json['keywords'] as List? ?? const []))
            if (normalizeForMatch(k as String).isNotEmpty) normalizeForMatch(k),
        ],
        patterns: [
          for (final p in (json['patterns'] as List? ?? const []))
            ?_compile(p as String),
        ],
      );

  final String id;

  /// Normalised, matched on word boundaries.
  final List<String> keywords;

  /// Over one normalised word ("hahaha").
  final List<RegExp> patterns;
}

RegExp? _compile(String source) {
  try {
    return RegExp(source, unicode: true);
  } on FormatException {
    return null;
  }
}

const _plain = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final _toPlain = {
  for (final e in _plain.entries)
    for (final c in e.value.split('')) c: e.key,
};
final _combiningMarks = RegExp('[̀-ͯ]');
final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lower case, no diacritics, letters and digits only, single spaces:
/// "Buồn  ngủ!" and "buon ngu" are the same text.
String normalizeForMatch(String text) => text
    .toLowerCase()
    .replaceAll(_combiningMarks, '')
    .split('')
    .map((c) => _toPlain[c] ?? c)
    .join()
    .replaceAll(_separators, ' ')
    .trim();

/// The topic a short message is about, or null. The longest match wins, so
/// "buồn ngủ" is sleepy, not sad.
String? matchSuggestionTopic(String text, List<SuggestionTopic> topics) {
  final normalized = normalizeForMatch(text);
  if (normalized.isEmpty || normalized.length > maxSuggestionLength) {
    return null;
  }
  final words = normalized.split(' ');
  if (words.length > maxSuggestionWords) return null;

  final padded = ' $normalized ';
  String? best;
  var bestLength = 0;
  void consider(String id, int length) {
    if (length > bestLength) (best, bestLength) = (id, length);
  }

  for (final topic in topics) {
    for (final keyword in topic.keywords) {
      if (padded.contains(' $keyword ')) consider(topic.id, keyword.length);
    }
    for (final word in words) {
      if (topic.patterns.any((p) => p.hasMatch(word))) {
        consider(topic.id, word.length);
      }
    }
  }
  return best;
}

// Per conversation, on this device. ponytail: keys are never pruned; a few
// bytes per conversation where a suggestion was ever closed.
String _dismissedKey(String id) => 'nowa:sticker-suggest-dismissed:$id';
String _mutedKey(String id) => 'nowa:sticker-suggest-muted:$id';

bool isSuggestionMuted(SharedPreferences prefs, String id, DateTime now) =>
    (prefs.getInt(_mutedKey(id)) ?? 0) > now.millisecondsSinceEpoch;

/// The suggestion was closed, or the message sent past it. Returns whether
/// the conversation is now silenced.
bool recordSuggestionDismissed(
  SharedPreferences prefs,
  String id,
  DateTime now,
) {
  final dismissed = (prefs.getInt(_dismissedKey(id)) ?? 0) + 1;
  if (dismissed < suggestionDismissLimit) {
    prefs.setInt(_dismissedKey(id), dismissed);
    return false;
  }
  prefs
    ..remove(_dismissedKey(id))
    ..setInt(_mutedKey(id), now.add(suggestionMute).millisecondsSinceEpoch);
  return true;
}

/// A suggested sticker was sent: the count of ignored ones starts over.
void recordSuggestionUsed(SharedPreferences prefs, String id) =>
    prefs.remove(_dismissedKey(id));
