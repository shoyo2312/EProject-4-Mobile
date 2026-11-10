import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_mobile/features/chat/data/sticker_suggestions.dart';

void main() {
  // The same shape chat-service serves from suggestion-topics.json.
  final topics = [
    {
      'id': 'sad',
      'keywords': ['buồn', 'khóc'],
      'patterns': ['^(hu){2,}\$'],
    },
    {
      'id': 'sleepy',
      'keywords': ['buồn ngủ', 'ngủ ngon'],
      'patterns': <String>[],
    },
    {
      'id': 'hello',
      'keywords': ['chào', 'hi'],
      'patterns': ['('], // does not compile: dropped, not fatal
    },
  ].map(SuggestionTopic.fromJson).toList();

  test('normalises case, marks and punctuation', () {
    expect(normalizeForMatch('  Buồn  NGỦ!! '), 'buon ngu');
    expect(normalizeForMatch('Đi đâu?'), 'di dau');
  });

  test('matches short messages, with or without marks', () {
    expect(matchSuggestionTopic('buồn quá', topics), 'sad');
    expect(matchSuggestionTopic('buon qua', topics), 'sad');
    expect(matchSuggestionTopic('huhuhu', topics), 'sad');
    expect(matchSuggestionTopic('Chào!', topics), 'hello');
  });

  test('the longest match wins', () {
    expect(matchSuggestionTopic('buồn ngủ', topics), 'sleepy');
  });

  test('nothing for long text, partial words or no match', () {
    expect(matchSuggestionTopic('hôm nay tôi buồn lắm', topics), isNull);
    expect(matchSuggestionTopic('hihi', topics), isNull);
    expect(matchSuggestionTopic('ok', topics), isNull);
  });

  test('two dismissals in a row silence the conversation for a day', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 11, 10);

    expect(recordSuggestionDismissed(prefs, 'c1', now), isFalse);
    recordSuggestionUsed(prefs, 'c1'); // a used one resets the count
    expect(recordSuggestionDismissed(prefs, 'c1', now), isFalse);
    expect(isSuggestionMuted(prefs, 'c1', now), isFalse);
    expect(recordSuggestionDismissed(prefs, 'c1', now), isTrue);
    expect(isSuggestionMuted(prefs, 'c1', now), isTrue);
    expect(isSuggestionMuted(prefs, 'c2', now), isFalse);
    expect(
      isSuggestionMuted(prefs, 'c1', now.add(const Duration(hours: 25))),
      isFalse,
    );
  });
}
