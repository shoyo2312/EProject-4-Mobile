import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';

class MockInteractionRepository extends Mock implements InteractionRepository {}

LikeStatus status({required bool liked, required int likeCount}) =>
    LikeStatus(videoId: 'v1', liked: liked, likeCount: likeCount);

void main() {
  late MockInteractionRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockInteractionRepository();
    container = ProviderContainer(
      overrides: [interactionRepositoryProvider.overrideWithValue(repository)],
    );
    when(() => repository.getLikeStatus('v1'))
        .thenAnswer((_) async => status(liked: false, likeCount: 5));
  });

  tearDown(() => container.dispose());

  test('the server count replaces the optimistic guess', () async {
    // Someone else liked it in between, so the real count is not 5 + 1.
    when(() => repository.like('v1'))
        .thenAnswer((_) async => status(liked: true, likeCount: 9));
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).toggle();

    final result = container.read(likeNotifierProvider('v1')).value!;
    expect(result.liked, isTrue);
    expect(result.likeCount, 9);
  });

  test('a failed write puts the heart back', () async {
    when(() => repository.like('v1')).thenThrow(const NetworkException());
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).toggle();

    final result = container.read(likeNotifierProvider('v1')).value!;
    expect(result.liked, isFalse);
    expect(result.likeCount, 5);
  });

  test('double-tapping an already-liked video sends nothing', () async {
    when(() => repository.getLikeStatus('v1'))
        .thenAnswer((_) async => status(liked: true, likeCount: 5));
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).like();

    verifyNever(() => repository.like(any()));
    verifyNever(() => repository.unlike(any()));
  });
}
