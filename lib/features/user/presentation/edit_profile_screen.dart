import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/edit_profile_rules.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Edit profile — the same fields and rules as the web client's modal: photo,
/// username (once every 30 days), name (once every 7), bio.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(myProfileProvider);
    final account = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: NowaColors.bg,
      body: profileState.when(
        loading: () => const _Shell(child: LoadingView()),
        error: (error, _) => _Shell(
          child: ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
        ),
        // Signed out mid-edit: the router is already on its way to /login.
        data: (profile) => account == null
            ? const _Shell(child: LoadingView())
            : _EditProfileForm(original: profile, account: account),
      ),
    );
  }
}

/// App bar + body for the states that have no form yet.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const NowaAppBar(title: 'Edit profile'),
        Expanded(child: child),
      ],
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.original, required this.account});

  /// The stored profile. Replaced by the provider after each save step, so a
  /// step that went through stops counting as a change.
  final UserProfileModel original;
  final UserModel account;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final _usernameController = TextEditingController(
    text: widget.account.username,
  );
  late final _displayNameController = TextEditingController(
    text: widget.original.displayName,
  );
  late final _bioController = TextEditingController(
    text: widget.original.bio ?? '',
  );

  /// The picked photo, held until Save. Nothing is uploaded on pick, so
  /// leaving the screen leaves the account exactly as it was.
  File? _avatarFile;
  String? _avatarContentType;

  String? _avatarError;
  String? _usernameError;
  String? _displayNameError;
  String? _saveError;
  bool _isSaving = false;

  /// What the server will store: an SVG is an image to a picker and a script
  /// host to a browser, so it is not on the list.
  static const _avatarTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// The server's own ceiling (`app.avatar.max-bytes`), checked here so a
  /// 20 MB photo is refused before it is sent over a phone connection.
  static const _maxAvatarBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    // Typing into a field clears its complaint and re-evaluates Save.
    _usernameController.addListener(() => _onEdited(username: true));
    _displayNameController.addListener(() => _onEdited(displayName: true));
    _bioController.addListener(_onEdited);
  }

  void _onEdited({bool username = false, bool displayName = false}) {
    setState(() {
      if (username) _usernameError = null;
      if (displayName) _displayNameError = null;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  DateTime? get _usernameLockedUntil =>
      lockedUntil(widget.account.usernameChangeableAt);

  DateTime? get _displayNameLockedUntil =>
      lockedUntil(widget.original.displayNameChangeableAt);

  ({String? username, String? displayName, String? bio}) get _changes =>
      changedProfileFields(
        username: _usernameController.text,
        displayName: _displayNameController.text,
        bio: _bioController.text,
        currentUsername: widget.account.username,
        currentDisplayName: widget.original.displayName,
        currentBio: widget.original.bio ?? '',
      );

  bool get _dirty {
    final c = _changes;
    return _avatarFile != null ||
        c.username != null ||
        c.displayName != null ||
        c.bio != null;
  }

  Future<void> _pickAvatar() async {
    if (_isSaving) return;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } on Exception {
      // A refused photo-library permission arrives as an exception, not null.
      if (mounted) setState(() => _avatarError = 'Photo access was refused.');
      return;
    }
    if (picked == null || !mounted) return;

    final extension = picked.path.split('.').last.toLowerCase();
    final contentType = _avatarTypes[extension];
    if (contentType == null) {
      setState(() => _avatarError = 'Choose a JPEG, PNG, or WebP image.');
      return;
    }
    final file = File(picked.path);
    if (await file.length() > _maxAvatarBytes) {
      if (mounted) setState(() => _avatarError = 'That image is over 5 MB.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _avatarError = null;
      _avatarFile = file;
      _avatarContentType = contentType;
    });
  }

  Future<void> _save() async {
    final changes = _changes;
    final usernameProblem = changes.username == null
        ? null
        : usernameError(changes.username!, current: widget.account.username);
    final displayNameProblem = changes.displayName == null
        ? null
        : displayNameError(changes.displayName!);
    if (usernameProblem != null || displayNameProblem != null) {
      setState(() {
        _usernameError = usernameProblem;
        _displayNameError = displayNameProblem;
      });
      return;
    }

    setState(() {
      _saveError = null;
      _isSaving = true;
    });
    try {
      // The photo first: picking only previewed a local file. Then the
      // profile text — only what changed, because an empty string on this
      // endpoint deletes the field. The rename goes last, so a taken handle
      // (the most likely failure) leaves everything else already saved.
      final profile = ref.read(myProfileProvider.notifier);
      if (_avatarFile != null) {
        await profile.uploadAvatar(
          _avatarFile!,
          contentType: _avatarContentType!,
        );
        if (mounted) setState(() => _avatarFile = null);
      }

      final patch = <String, dynamic>{
        if (changes.displayName != null) 'displayName': changes.displayName,
        if (changes.bio != null) 'bio': changes.bio,
      };
      if (patch.isNotEmpty) await profile.updateProfile(patch);

      if (changes.username != null) {
        await ref
            .read(authStateProvider.notifier)
            .changeUsername(changes.username!);
      }

      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _saveError = saveErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Back with unsaved edits asks first, the way the web modal refuses to
  /// close on a stray click.
  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NowaColors.surfaceHigh,
        title: Text('Discard changes?', style: sora(size: 16)),
        content: Text(
          "Your edits haven't been saved.",
          style: work(size: 13, color: NowaColors.dim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep editing',
              style: work(size: 14, color: NowaColors.dim),
            ),
          ),
          TextButton(
            key: const Key('edit_profile_discard_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Discard',
              style: work(size: 14, color: NowaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;
    final usernameLock = _usernameLockedUntil;
    final displayNameLock = _displayNameLockedUntil;
    final canSave = dirty && !_isSaving;

    return PopScope(
      canPop: !dirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Column(
        children: [
          NowaAppBar(
            title: 'Edit profile',
            actions: [
              TextButton(
                key: const Key('edit_profile_save_action'),
                onPressed: canSave ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NowaColors.accent,
                        ),
                      )
                    : Text(
                        'Save',
                        style: sora(
                          size: 14,
                          color: canSave
                              ? NowaColors.accent
                              : NowaColors.text.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AvatarPicker(
                    file: _avatarFile,
                    url: widget.original.avatarUrl,
                    onTap: _pickAvatar,
                  ),
                  if (_avatarError != null) ...[
                    const SizedBox(height: 8),
                    Center(child: _Tip(_avatarError!, error: true)),
                  ],
                  const SizedBox(height: 26),
                  _Section(
                    label: 'Username',
                    child: usernameLock != null
                        ? _Locked(
                            value: widget.account.username,
                            tip:
                                'You can change your username again on '
                                '${formatChangeableAt(usernameLock)}.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Field(
                                fieldKey: const Key(
                                  'edit_profile_username_field',
                                ),
                                controller: _usernameController,
                                hint: 'Username',
                                prefix: '@',
                                error: _usernameError != null,
                              ),
                              const SizedBox(height: 8),
                              _Tip(
                                'nowa.com/@${_usernameController.text.trim()}',
                              ),
                              const SizedBox(height: 4),
                              _usernameError != null
                                  ? _Tip(_usernameError!, error: true)
                                  : _Tip(
                                      'Usernames can only contain lowercase '
                                      'letters, numbers, underscores, and '
                                      'periods. Changing your username will '
                                      'also change your profile link.'
                                      '${_changes.username != null ? ' You can only change your username once every 30 days.' : ''}',
                                    ),
                            ],
                          ),
                  ),
                  _Section(
                    label: 'Name',
                    child: displayNameLock != null
                        ? _Locked(
                            value: widget.original.displayName,
                            tip:
                                'You can change your nickname again on '
                                '${formatChangeableAt(displayNameLock)}.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Field(
                                fieldKey: const Key(
                                  'edit_profile_display_name_field',
                                ),
                                controller: _displayNameController,
                                hint: 'Name',
                                maxLength: kDisplayNameMaxLength,
                                error: _displayNameError != null,
                              ),
                              const SizedBox(height: 4),
                              _displayNameError != null
                                  ? _Tip(_displayNameError!, error: true)
                                  : const _Tip(
                                      'Your nickname can only be changed '
                                      'once every 7 days.',
                                    ),
                            ],
                          ),
                  ),
                  _Section(
                    label: 'Bio',
                    last: true,
                    child: _Field(
                      fieldKey: const Key('edit_profile_bio_field'),
                      controller: _bioController,
                      hint: 'Bio',
                      maxLength: kBioMaxLength,
                      maxLines: 4,
                      showCounter: true,
                    ),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _saveError!,
                      key: const Key('edit_profile_save_error'),
                      style: work(size: 13, color: NowaColors.danger),
                    ),
                  ],
                  const SizedBox(height: 28),
                  NowaButton(
                    key: const Key('edit_profile_save_button'),
                    label: 'Save',
                    height: 50,
                    loading: _isSaving,
                    onTap: canSave ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.file,
    required this.url,
    required this.onTap,
  });

  /// A photo picked but not saved yet — shown instead of [url].
  final File? file;
  final String? url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        key: const Key('edit_profile_avatar_picker'),
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.file(
                          file!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    : NowaAvatar(url: url ?? '', size: 96, radius: 32),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: NowaColors.surfaceHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: NowaColors.bg, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Change photo',
              style: work(size: 13, color: NowaColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled block with a hairline under it, like the web modal's rows.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: NowaColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label.toUpperCase()),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// A field that cannot change yet: its value, dimmed, and when it opens.
class _Locked extends StatelessWidget {
  const _Locked({required this.value, required this.tip});

  final String value;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: NowaColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: work(
                    size: 14.5,
                    color: NowaColors.text.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: NowaColors.text.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Tip(tip),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: work(
        size: 11.5,
        height: 1.45,
        color: error
            ? NowaColors.danger
            : NowaColors.text.withValues(alpha: 0.45),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    this.prefix,
    this.maxLength,
    this.maxLines = 1,
    this.showCounter = false,
    this.error = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final int? maxLength;
  final int maxLines;
  final bool showCounter;
  final bool error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: error ? BorderSide(color: color) : BorderSide.none,
    );
    return TextField(
      key: fieldKey,
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      autocorrect: false,
      cursorColor: NowaColors.accent,
      style: work(size: 14.5, height: 1.35),
      decoration: InputDecoration(
        filled: true,
        fillColor: NowaColors.surfaceHigh,
        hintText: hint,
        hintStyle: work(
          size: 14.5,
          color: NowaColors.text.withValues(alpha: 0.3),
        ),
        prefixText: prefix,
        prefixStyle: work(
          size: 14.5,
          color: NowaColors.text.withValues(alpha: 0.5),
        ),
        // The counter is only worth its line under the bio.
        counterText: showCounter ? null : '',
        counterStyle: work(
          size: 11,
          color: NowaColors.text.withValues(alpha: 0.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(NowaColors.danger),
        enabledBorder: border(NowaColors.danger),
        focusedBorder: border(NowaColors.danger),
      ),
    );
  }
}
