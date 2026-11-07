import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/user/data/comment_filter_settings.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/comment_filters_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.getCommentFilters()).thenAnswer(
      (_) async => const CommentFilterSettings(commentKeywords: ['spoiler']),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: CommentFiltersScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Switch switchOf(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(Key(key)));

  testWidgets('shows what the server has', (tester) async {
    await pumpScreen(tester);

    expect(switchOf(tester, 'comment_filters_spam_switch').value, isTrue);
    expect(switchOf(tester, 'comment_filters_all_switch').value, isFalse);
    expect(find.text('spoiler'), findsOneWidget);
  });

  testWidgets('a switch sends only its own key', (tester) async {
    when(() => repository.updateCommentFilters(any())).thenAnswer(
      (_) async => const CommentFilterSettings(
        filterAllComments: true,
        commentKeywords: ['spoiler'],
      ),
    );
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('comment_filters_all_switch')));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateCommentFilters({'filterAllComments': true}),
    ).called(1);
    expect(switchOf(tester, 'comment_filters_all_switch').value, isTrue);
  });

  testWidgets('a refused change flips the switch back', (tester) async {
    when(
      () => repository.updateCommentFilters(any()),
    ).thenThrow(const NetworkException());
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('comment_filters_spam_switch')));
    await tester.pumpAndSettle();

    expect(switchOf(tester, 'comment_filters_spam_switch').value, isTrue);
    expect(find.text('No internet connection'), findsOneWidget);
  });

  testWidgets('adding a keyword sends the whole list', (tester) async {
    when(() => repository.updateCommentFilters(any())).thenAnswer(
      (_) async =>
          const CommentFilterSettings(commentKeywords: ['spoiler', 'giảm giá']),
    );
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('comment_filters_keyword_field')),
      '  giảm giá ',
    );
    await tester.tap(find.byKey(const Key('comment_filters_add_keyword')));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateCommentFilters({
        'commentKeywords': ['spoiler', 'giảm giá'],
      }),
    ).called(1);
    expect(find.text('giảm giá'), findsOneWidget);
  });

  testWidgets('a duplicate keyword is caught before it is sent', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('comment_filters_keyword_field')),
      'SPOILER',
    );
    await tester.tap(find.byKey(const Key('comment_filters_add_keyword')));
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateCommentFilters(any()));
    expect(find.text('"SPOILER" is already on your list'), findsOneWidget);
  });

  testWidgets('removing a keyword sends the list without it', (tester) async {
    when(
      () => repository.updateCommentFilters(any()),
    ).thenAnswer((_) async => const CommentFilterSettings());
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('comment_filters_remove_spoiler')));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateCommentFilters({'commentKeywords': <String>[]}),
    ).called(1);
    expect(find.text('spoiler'), findsNothing);
  });
}
