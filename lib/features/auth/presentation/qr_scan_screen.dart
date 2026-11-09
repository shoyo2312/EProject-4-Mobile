import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/data/qr_login_scan.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

/// What the confirm screen needs, passed as `extra`: the claimed code and the
/// browser it belongs to.
class QrLoginConfirmArgs {
  const QrLoginConfirmArgs({required this.qrId, required this.scan});

  final String qrId;
  final QrLoginScan scan;
}

/// A user-facing sentence for a failed QR step, from the server's `code`.
String qrLoginErrorMessage(Object error) {
  if (error is ServerException) {
    switch (error.code) {
      case 'QR_LOGIN_EXPIRED':
        return 'This code has expired. Refresh it on the computer and scan again.';
      case 'QR_LOGIN_ALREADY_SCANNED':
        return 'Someone else already scanned this code.';
      case 'QR_LOGIN_NOT_ALLOWED':
        return "This account can't log in on the web with a QR code.";
    }
  }
  if (error is AppException) return error.message;
  return 'Something went wrong, try again.';
}

/// Camera view for the code shown on the web's "Log in with QR code" screen.
/// Only `nowa://qr-login?id=…` is acted on; a successful scan claims the code
/// for this account and moves on to the confirm screen.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _busy = false;

  /// The last foreign code complained about, so holding the camera on it
  /// does not stack up one snackbar per frame.
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final qrId = qrLoginIdFrom(raw);
    if (qrId == null) {
      if (raw != _lastRejected) {
        _lastRejected = raw;
        _toast('This is not a Nowa web login code.');
      }
      return;
    }

    setState(() => _busy = true);
    await _controller.stop();
    try {
      final scan = await ref.read(authRepositoryProvider).scanQrLogin(qrId);
      if (!mounted) return;
      context.pushReplacement(
        '/me/qr-login/confirm',
        extra: QrLoginConfirmArgs(qrId: qrId, scan: scan),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      _toast(qrLoginErrorMessage(e));
      setState(() => _busy = false);
      await _controller.start();
    }
  }

  void _toast(String message) {
    NowaToast.of(context).error(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Log in on web'),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  key: const Key('qr_scanner'),
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraError(error: error),
                ),
                const _Frame(),
                if (_busy)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: Text(
              'On your computer, open Nowa and choose "Log in with QR code", '
              'then point your camera at the code.',
              textAlign: TextAlign.center,
              style: work(
                size: 13,
                height: 1.4,
                color: NowaColors.text.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The square the code should sit in.
class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NowaColors.accent, width: 3),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: NowaColors.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 36, color: NowaColors.text.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                denied
                    ? 'Allow camera access in Settings to scan the code.'
                    : 'The camera could not be started.',
                textAlign: TextAlign.center,
                style: sora(size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
