import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/user/presentation/edit_profile_rules.dart';

void main() {
  group('usernameError', () {
    test('the current handle passes even when it breaks the rule', () {
      expect(usernameError('1legacy', current: '1legacy'), isNull);
    });

    test('a new handle must follow the rule', () {
      String? check(String v) => usernameError(v, current: 'jane');
      expect(check(''), 'Enter a username.');
      expect(check('a@b.com'), contains('email'));
      expect(check('ja ne'), contains('spaces'));
      expect(check('Jane2'), 'Usernames are lowercase only.');
      expect(check('ab'), contains('at least 3'));
      expect(check('a' * 51), contains('at most 50'));
      expect(check('2jane'), 'Usernames must start with a letter.');
      expect(check('jane-doe'), contains('underscores and periods'));
      expect(check('jane.doe_2'), isNull);
    });
  });

  test('displayNameError', () {
    expect(displayNameError('   '), 'Enter a name.');
    expect(displayNameError('a' * 31), contains('at most 30'));
    expect(displayNameError('Jane'), isNull);
  });

  test('lockedUntil is null once the date has passed', () {
    final now = DateTime(2026, 11, 6);
    expect(lockedUntil(null, now: now), isNull);
    expect(lockedUntil(DateTime(2026, 11, 1), now: now), isNull);
    expect(
      lockedUntil(DateTime(2026, 11, 10), now: now),
      DateTime(2026, 11, 10),
    );
  });

  test('changedProfileFields ignores surrounding spaces', () {
    final changes = changedProfileFields(
      username: 'jane ',
      displayName: ' Jane D',
      bio: 'hello',
      currentUsername: 'jane',
      currentDisplayName: 'Jane',
      currentBio: 'hello ',
    );
    expect(changes.username, isNull);
    expect(changes.displayName, 'Jane D');
    expect(changes.bio, isNull);
  });

  test('saveErrorMessage maps known codes and falls back to the message', () {
    expect(
      saveErrorMessage(
        const ServerException(
          409,
          'Username already taken: jane',
          code: 'USERNAME_ALREADY_EXISTS',
        ),
      ),
      'That username is taken.',
    );
    expect(
      saveErrorMessage(const ServerException(500, 'Boom', code: 'X')),
      'Boom',
    );
  });

  group('birthday', () {
    test('the latest allowed day is 13 years back', () {
      expect(
        latestBirthDate(now: DateTime(2026, 11, 9)),
        DateTime(2013, 11, 9),
      );
    });

    test('Feb 29 falls back to Feb 28, like the server', () {
      expect(
        latestBirthDate(now: DateTime(2028, 2, 29)),
        DateTime(2015, 2, 28),
      );
    });

    test('sent as yyyy-MM-dd, shown as dd/MM/yyyy', () {
      expect(birthDateToJson(DateTime(2001, 5, 9)), '2001-05-09');
      expect(formatBirthDate(DateTime(2001, 5, 9)), '09/05/2001');
    });
  });
}
