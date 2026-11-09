import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/data/session_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/sessions_provider.dart';

/// Where the account is signed in: device, place, sign-in time, and a button
/// to sign each one out remotely. An account holds one laptop/PC and one
/// phone/tablet; signing in on another of the same kind signs the old one out.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Devices'),
      body: sessions.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(sessionsProvider),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(sessionsProvider.future),
          child: ListView(
            key: const Key('devices_list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              Text(
                'You can be signed in on one laptop/PC and one phone/tablet '
                'at a time. Signing in on another device of the same kind '
                'signs the old one out.',
                style: work(
                  size: 12.5,
                  height: 1.4,
                  color: NowaColors.text.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 18),
              for (final session in list) ...[
                _SessionTile(session: session),
                const SizedBox(height: 12),
              ],
              if (list.where((s) => !s.current).length > 1) ...[
                const SizedBox(height: 8),
                NowaButton(
                  key: const Key('devices_sign_out_others'),
                  label: 'Log out all other devices',
                  filled: false,
                  icon: Icons.logout,
                  onTap: () => _confirm(
                    context,
                    'Log out all other devices?',
                    () => ref.read(sessionsProvider.notifier).signOutOthers(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dim = NowaColors.text.withValues(alpha: 0.5);
    final name = session.deviceLabel ?? _fallbackName(session);
    return Container(
      key: Key('session_${session.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.current
              ? NowaColors.accent.withValues(alpha: 0.5)
              : NowaColors.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(session), color: NowaColors.text, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: sora(size: 14)),
                if (session.current) ...[
                  const SizedBox(height: 3),
                  Text('This device',
                      style: sora(size: 11, color: NowaColors.accent)),
                ],
                const SizedBox(height: 6),
                _line(Icons.place_outlined,
                    session.location ?? 'Unknown location', dim),
                _line(Icons.login, 'Signed in ${_format(session.signedInAt)}',
                    dim),
                if (!session.current)
                  _line(Icons.schedule,
                      'Last active ${_format(session.lastActiveAt)}', dim),
              ],
            ),
          ),
          TextButton(
            key: Key('session_sign_out_${session.id}'),
            onPressed: () => session.current
                ? _confirm(
                    context,
                    'Log out of this device?',
                    () => ref.read(authStateProvider.notifier).logout(),
                  )
                : _confirm(
                    context,
                    'Log out $name?',
                    () => ref
                        .read(sessionsProvider.notifier)
                        .signOut(session.id),
                  ),
            child: Text('Log out',
                style: sora(size: 12.5, color: NowaColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text, style: work(size: 12, height: 1.3, color: color)),
            ),
          ],
        ),
      );

  static IconData _icon(SessionModel s) => switch (s.deviceType) {
        DeviceType.desktop => Icons.laptop_windows_outlined,
        DeviceType.mobile => Icons.smartphone_outlined,
        DeviceType.unknown => Icons.devices_other_outlined,
      };

  static String _fallbackName(SessionModel s) => switch (s.deviceType) {
        DeviceType.desktop => 'Laptop / PC',
        DeviceType.mobile => 'Phone / Tablet',
        DeviceType.unknown => 'Unknown device',
      };

  /// "03/11/2026 09:41", local time.
  static String _format(DateTime when) {
    final t = when.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

Future<void> _confirm(
  BuildContext context,
  String title,
  Future<void> Function() action,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: NowaColors.surfaceHigh,
      title: Text(title, style: sora(size: 15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: sora(size: 13, color: NowaColors.dim)),
        ),
        TextButton(
          key: const Key('devices_confirm_sign_out'),
          onPressed: () => Navigator.of(context).pop(true),
          child:
              Text('Log out', style: sora(size: 13, color: NowaColors.danger)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final toast = NowaToast.of(context);
  try {
    await action();
  } on AppException catch (e) {
    toast.error(e.message);
  }
}
