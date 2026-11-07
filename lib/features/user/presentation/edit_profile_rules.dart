import 'package:tiktok_mobile/core/network/app_exception.dart';

/// The Edit profile rules, kept the same as the web client's modal
/// (`EditProfileModal` + `editProfileSchemaFor`) so both apps accept and refuse
/// the same input.

/// Nickname cap. user-service allows 100, the web form 30 — the web limit wins
/// so a name saved here never looks truncated there.
const kDisplayNameMaxLength = 30;

/// Bio cap, same reasoning: user-service allows 500, the web form 80.
const kBioMaxLength = 80;

/// The handle rule auth-service enforces (`UsernameRule`): 3–50 lowercase
/// letters, digits, underscores or periods, starting with a letter. One
/// problem at a time, in the order people fix them.
///
/// Checked only once the handle is edited: an older handle that breaks the
/// rule (a generated one can start with a digit) is the owner's to keep and
/// must not stop them saving a new bio.
String? usernameError(String value, {required String current}) {
  final v = value.trim();
  if (v == current) return null;
  if (v.isEmpty) return 'Enter a username.';
  if (v.contains('@')) {
    return "A username isn't an email address — leave out the \"@\".";
  }
  if (RegExp(r'\s').hasMatch(v)) return "Usernames can't contain spaces.";
  if (v != v.toLowerCase()) return 'Usernames are lowercase only.';
  if (v.length < 3) return 'Usernames need at least 3 characters.';
  if (v.length > 50) return 'Usernames can be at most 50 characters.';
  if (!RegExp(r'^[a-z]').hasMatch(v)) {
    return 'Usernames must start with a letter.';
  }
  if (!RegExp(r'^[a-z0-9._]+$').hasMatch(v)) {
    return 'Use lowercase letters, numbers, underscores and periods only.';
  }
  return null;
}

String? displayNameError(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Enter a name.';
  if (v.length > kDisplayNameMaxLength) {
    return 'Names can be at most $kDisplayNameMaxLength characters.';
  }
  return null;
}

/// When a rename lock lifts, or null when the field is open now. A lock that
/// has already passed counts as open; the server still refuses a change made
/// too soon, so failing open is safe.
DateTime? lockedUntil(DateTime? changeableAt, {DateTime? now}) {
  if (changeableAt == null) return null;
  return changeableAt.isAfter(now ?? DateTime.now()) ? changeableAt : null;
}

/// The text fields that differ from what is stored, as the trimmed values to
/// send. Both sides are trimmed: a draft that only gained a space changes
/// nothing, and must not spend the nickname's week.
({String? username, String? displayName, String? bio}) changedProfileFields({
  required String username,
  required String displayName,
  required String bio,
  required String currentUsername,
  required String currentDisplayName,
  required String currentBio,
}) {
  String? diff(String next, String current) =>
      next.trim() == current.trim() ? null : next.trim();
  return (
    username: diff(username, currentUsername),
    displayName: diff(displayName, currentDisplayName),
    bio: diff(bio, currentBio),
  );
}

/// `dd/MM/yyyy HH:mm` in local time — the format the Devices screen uses.
String formatChangeableAt(DateTime at) {
  final t = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}

/// What to tell the user when a save step fails. The codes come from
/// auth-service (handle) and user-service (nickname); the wording is the web
/// client's.
String saveErrorMessage(AppException error) {
  if (error is ServerException) {
    switch (error.code) {
      case 'USERNAME_ALREADY_EXISTS':
        return 'That username is taken.';
      case 'USERNAME_CHANGE_TOO_SOON':
        return 'You can only change your username once every 30 days.';
      case 'DISPLAY_NAME_CHANGE_TOO_SOON':
        return 'Your nickname can only be changed once every 7 days.';
    }
  }
  return error.message;
}
