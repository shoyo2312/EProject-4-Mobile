import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/edit_profile_screen.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

/// Signed in as `jane`; records renames instead of calling auth-service.
class _FakeAuthState extends AuthState {
  _FakeAuthState({this.usernameChangeableAt, this.renameError});

  final DateTime? usernameChangeableAt;
  final AppException? renameError;
  final renames = <String>[];

  @override
  FutureOr<UserModel?> build() => UserModel(
    id: '1',
    username: 'jane',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
    usernameChangeableAt: usernameChangeableAt,
  );

  @override
  Future<void> changeUsername(String username) async {
    if (renameError != null) throw renameError!;
    renames.add(username);
    state = AsyncData(state.value!.copyWith(username: username));
  }
}

const _profile = UserProfileModel(
  userId: '1',
  displayName: 'Jane',
  bio: 'hello',
  followerCount: 0,
  followingCount: 0,
);

void main() {
  late MockUserRepository repository;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repository = MockUserRepository();
    when(() => repository.getMyProfile()).thenAnswer((_) async => _profile);
  });

  Future<GoRouter> pumpScreen(
    WidgetTester tester, {
    required _FakeAuthState auth,
    UserProfileModel profile = _profile,
  }) async {
    when(() => repository.getMyProfile()).thenAnswer((_) async => profile);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/edit', builder: (_, _) => const EditProfileScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith(() => auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
    return router;
  }

  NowaButton saveButton(WidgetTester tester) => tester.widget<NowaButton>(
    find.byKey(const Key('edit_profile_save_button')),
  );

  testWidgets('Save stays off until something changes', (tester) async {
    await pumpScreen(tester, auth: _FakeAuthState());

    expect(saveButton(tester).onTap, isNull);

    await tester.enterText(
      find.byKey(const Key('edit_profile_bio_field')),
      'new bio',
    );
    await tester.pump();
    expect(saveButton(tester).onTap, isNotNull);
  });

  testWidgets('sends only the changed fields, then closes', (tester) async {
    when(
      () => repository.updateMyProfile(any()),
    ).thenAnswer((_) async => _profile.copyWith(bio: 'new bio'));
    final auth = _FakeAuthState();
    await pumpScreen(tester, auth: auth);

    await tester.enterText(
      find.byKey(const Key('edit_profile_bio_field')),
      'new bio',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit_profile_save_action')));
    await tester.pumpAndSettle();

    verify(() => repository.updateMyProfile({'bio': 'new bio'})).called(1);
    expect(auth.renames, isEmpty);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a new username goes to auth-service', (tester) async {
    final auth = _FakeAuthState();
    await pumpScreen(tester, auth: auth);

    await tester.enterText(
      find.byKey(const Key('edit_profile_username_field')),
      'jane.doe',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit_profile_save_action')));
    await tester.pumpAndSettle();

    expect(auth.renames, ['jane.doe']);
    verifyNever(() => repository.updateMyProfile(any()));
  });

  testWidgets('a username that breaks the rule is refused before sending', (
    tester,
  ) async {
    final auth = _FakeAuthState();
    await pumpScreen(tester, auth: auth);

    await tester.enterText(
      find.byKey(const Key('edit_profile_username_field')),
      'Jane',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit_profile_save_action')));
    await tester.pumpAndSettle();

    expect(find.text('Usernames are lowercase only.'), findsOneWidget);
    expect(auth.renames, isEmpty);
  });

  testWidgets('a taken username shows why and keeps the screen open', (
    tester,
  ) async {
    final auth = _FakeAuthState(
      renameError: const ServerException(
        409,
        'Username already taken',
        code: 'USERNAME_ALREADY_EXISTS',
      ),
    );
    await pumpScreen(tester, auth: auth);

    await tester.enterText(
      find.byKey(const Key('edit_profile_username_field')),
      'taken',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit_profile_save_action')));
    await tester.pumpAndSettle();

    expect(find.text('That username is taken.'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('locked fields are read-only and say when they open', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      auth: _FakeAuthState(usernameChangeableAt: DateTime(2099, 1, 1)),
      profile: _profile.copyWith(displayNameChangeableAt: DateTime(2099, 1, 1)),
    );

    expect(find.byKey(const Key('edit_profile_username_field')), findsNothing);
    expect(
      find.byKey(const Key('edit_profile_display_name_field')),
      findsNothing,
    );
    expect(
      find.textContaining('You can change your username again on'),
      findsOneWidget,
    );
    expect(
      find.textContaining('You can change your nickname again on'),
      findsOneWidget,
    );
  });

  testWidgets('back with unsaved edits asks first', (tester) async {
    await pumpScreen(tester, auth: _FakeAuthState());

    await tester.enterText(
      find.byKey(const Key('edit_profile_bio_field')),
      'draft',
    );
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit_profile_discard_button')));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
