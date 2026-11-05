import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/qr_scan_screen.dart';

enum _Phase { asking, approving, done }

/// "Log in on this computer?" — the step that turns a scanned code into a web
/// session. Names the browser and its rough location, because a code someone
/// else sent you looks exactly like your own until you read that.
///
/// Leaving without answering (Cancel, back) rejects the code, so the web page
/// stops waiting instead of timing out.
class QrConfirmScreen extends ConsumerStatefulWidget {
  const QrConfirmScreen({super.key, required this.args});

  final QrLoginConfirmArgs args;

  @override
  ConsumerState<QrConfirmScreen> createState() => _QrConfirmScreenState();
}

class _QrConfirmScreenState extends ConsumerState<QrConfirmScreen> {
  _Phase _phase = _Phase.asking;
  late Duration _left = _remaining();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left = _remaining());
      if (_left == Duration.zero) _ticker?.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _remaining() {
    final left = widget.args.scan.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get _expired => _left == Duration.zero;

  Future<void> _approve() async {
    setState(() => _phase = _Phase.approving);
    try {
      await ref.read(authRepositoryProvider).approveQrLogin(widget.args.qrId);
      _ticker?.cancel();
      if (mounted) setState(() => _phase = _Phase.done);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.asking);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(qrLoginErrorMessage(e))));
    }
  }

  /// Best effort: the code dies on its own within minutes anyway.
  void _rejectQuietly() {
    ref
        .read(authRepositoryProvider)
        .rejectQrLogin(widget.args.qrId)
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _phase == _Phase.asking && !_expired) _rejectQuietly();
      },
      child: Scaffold(
        backgroundColor: NowaColors.bg,
        appBar: const NowaAppBar(title: 'Log in on web'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: _phase == _Phase.done ? _done(context) : _asking(context),
          ),
        ),
      ),
    );
  }

  Widget _asking(BuildContext context) {
    final scan = widget.args.scan;
    final dim = NowaColors.text.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.laptop_windows_outlined, size: 56, color: NowaColors.text),
        const SizedBox(height: 18),
        Text('Log in on this computer?',
            textAlign: TextAlign.center, style: sora(size: 19)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NowaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NowaColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(Icons.public, scan.deviceLabel ?? 'Unknown browser',
                  NowaColors.text, key: const Key('qr_confirm_device')),
              const SizedBox(height: 6),
              _line(Icons.place_outlined, scan.location ?? 'Unknown location', dim,
                  key: const Key('qr_confirm_location')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Only continue if you are signing in on this computer right now. '
          'Never scan a code someone else sent you — they would get into your account.',
          style: work(size: 12.5, height: 1.4, color: dim),
        ),
        const Spacer(),
        Text(
          _expired
              ? 'This code has expired. Refresh it on the computer and scan again.'
              : 'Code expires in ${_left.inSeconds}s',
          key: const Key('qr_confirm_countdown'),
          textAlign: TextAlign.center,
          style: work(size: 12, color: _expired ? NowaColors.danger : dim),
        ),
        const SizedBox(height: 12),
        NowaButton(
          key: const Key('qr_confirm_approve'),
          label: 'Log in',
          loading: _phase == _Phase.approving,
          onTap: _expired ? null : _approve,
        ),
        const SizedBox(height: 10),
        NowaButton(
          key: const Key('qr_confirm_cancel'),
          label: 'Cancel',
          filled: false,
          onTap: _phase == _Phase.approving ? null : () => context.pop(),
        ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_outline, size: 64, color: NowaColors.accent),
        const SizedBox(height: 16),
        Text("You're logged in on the computer",
            key: const Key('qr_confirm_done'),
            textAlign: TextAlign.center,
            style: sora(size: 17)),
        const SizedBox(height: 8),
        Text(
          'You can sign it out any time from Devices.',
          textAlign: TextAlign.center,
          style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.6)),
        ),
        const Spacer(),
        NowaButton(label: 'Done', onTap: () => context.pop()),
      ],
    );
  }

  Widget _line(IconData icon, String text, Color color, {Key? key}) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, key: key, style: work(size: 14, color: color))),
        ],
      );
}
