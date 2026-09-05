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
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Edit profile'),
      body: profileState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) => _EditProfileForm(original: profile),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.original});

  final UserProfileModel original;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final _displayNameController =
      TextEditingController(text: widget.original.displayName);
  late final _bioController = TextEditingController(text: widget.original.bio ?? '');

  String? _error;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  /// What the server will actually store: an SVG is an image to a picker and a
  /// script host to a browser, so it is not on the list.
  static const _avatarTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// The server's own ceiling (`app.avatar.max-bytes`). Checked here so a
  /// 20 MB photo is refused before it is uploaded over a phone connection.
  static const _maxAvatarBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Picks a picture and replaces the avatar with it in one call — the profile
  /// that comes back already points at the stored file, so there is nothing to
  /// save afterwards and nothing for the form to carry.
  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar) return;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } on Exception {
      // A refused photo-library permission arrives as an exception, not null.
      setState(() => _error = 'Photo access was refused');
      return;
    }
    if (picked == null) return;

    final extension = picked.path.split('.').last.toLowerCase();
    final contentType = _avatarTypes[extension];
    if (contentType == null) {
      setState(() => _error = 'Pick a JPG, PNG or WebP image');
      return;
    }
    final file = File(picked.path);
    if (await file.length() > _maxAvatarBytes) {
      if (!mounted) return;
      setState(() => _error = 'That image is larger than 5 MB');
      return;
    }

    setState(() {
      _error = null;
      _isUploadingAvatar = true;
    });
    try {
      await ref
          .read(myProfileProvider.notifier)
          .uploadAvatar(file, contentType: contentType);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    // Build the request body from only the fields the user actually
    // changed — sending unchanged fields as "" would delete them
    // (see user-service API doc section 3.2, partial-update semantics).
    final changes = <String, dynamic>{};

    final newDisplayName = _displayNameController.text.trim();
    if (newDisplayName != widget.original.displayName) {
      if (newDisplayName.isEmpty) {
        setState(() => _error = 'Display name cannot be empty');
        return;
      }
      changes['displayName'] = newDisplayName;
    }

    final newBio = _bioController.text;
    if (newBio != (widget.original.bio ?? '')) {
      changes['bio'] = newBio;
    }

    if (changes.isEmpty) {
      context.pop();
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      await ref.read(myProfileProvider.notifier).updateProfile(changes);
      if (mounted) context.pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              key: const Key('edit_profile_avatar_picker'),
              onTap: _pickAvatar,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      NowaAvatar(
                        // The stored URL, not a local preview: the upload
                        // finishes before this rebuilds, so there is never a
                        // moment where the two could disagree.
                        url: ref.watch(myProfileProvider).valueOrNull?.avatarUrl ??
                            widget.original.avatarUrl ??
                            '',
                        size: 96,
                        radius: 32,
                      ),
                      if (_isUploadingAvatar)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
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
          ),
          const SizedBox(height: 26),
          _Field(
            fieldKey: const Key('edit_profile_display_name_field'),
            controller: _displayNameController,
            label: 'Display name',
            maxLength: 100,
          ),
          const SizedBox(height: 18),
          _Field(
            fieldKey: const Key('edit_profile_bio_field'),
            controller: _bioController,
            label: 'Bio',
            helper: 'Leave empty to clear',
            maxLength: 500,
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: work(size: 13, color: NowaColors.danger)),
          ],
          const SizedBox(height: 28),
          NowaButton(
            key: const Key('edit_profile_save_button'),
            label: 'Save',
            height: 50,
            loading: _isSaving,
            onTap: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.helper,
    this.maxLength,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? helper;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label.toUpperCase()),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          cursorColor: NowaColors.accent,
          style: work(size: 14.5, height: 1.35),
          decoration: InputDecoration(
            filled: true,
            fillColor: NowaColors.surfaceHigh,
            counterStyle: work(
              size: 11,
              color: NowaColors.text.withValues(alpha: 0.3),
            ),
            helperText: helper,
            helperStyle: work(
              size: 11.5,
              color: NowaColors.text.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ],
    );
  }
}
