import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/follow_requests_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

UserProfileModel _user(String id) => UserProfileModel(
  userId: id,
  displayName: 'User $id',
  followerCount: 0,
  followingCount: 0,
);

void main() {
  late MockUserRepository repo;

  setUp(() {
    repo = MockUserRepository();
    when(() => repo.getFollowRequests(page: 0)).thenAnswer(
      (_) async => PageResponse(
        content: [_user('7'), _user('8')],
        size: 20,
        number: 0,
        totalElements: 2,
        totalPages: 1,
      ),
    );
    when(() => repo.getMyProfile()).thenAnswer((_) async => _user('1'));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: FollowRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Confirm approves and drops the row', (tester) async {
    when(() => repo.approveFollowRequest('7')).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.byKey(const Key('follow_request_confirm_7')));
    await tester.pumpAndSettle();

    verify(() => repo.approveFollowRequest('7')).called(1);
    expect(find.text('User 7'), findsNothing);
    expect(find.text('User 8'), findsOneWidget);
  });

  testWidgets('a request already answered elsewhere just goes', (tester) async {
    when(() => repo.declineFollowRequest('8')).thenThrow(
      const ServerException(404, 'gone', code: 'FOLLOW_REQUEST_NOT_FOUND'),
    );
    await pump(tester);

    await tester.tap(find.byKey(const Key('follow_request_delete_8')));
    await tester.pumpAndSettle();

    expect(find.text('User 8'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
