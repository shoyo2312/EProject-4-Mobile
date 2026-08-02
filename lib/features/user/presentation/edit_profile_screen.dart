import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
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
  late final _avatarUrlController =
      TextEditingController(text: widget.original.avatarUrl ?? '');

  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
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

    final newAvatarUrl = _avatarUrlController.text.trim();
    if (newAvatarUrl != (widget.original.avatarUrl ?? '')) {
      changes['avatarUrl'] = newAvatarUrl;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('edit_profile_display_name_field'),
            controller: _displayNameController,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          TextField(
            key: const Key('edit_profile_bio_field'),
            controller: _bioController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              helperText: 'Leave empty to clear',
            ),
          ),
          TextField(
            key: const Key('edit_profile_avatar_url_field'),
            controller: _avatarUrlController,
            decoration: const InputDecoration(
              labelText: 'Avatar URL',
              helperText: 'Must be an https URL from the upload flow',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('edit_profile_save_button'),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
