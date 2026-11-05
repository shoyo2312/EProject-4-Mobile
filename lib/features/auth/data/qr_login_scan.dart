import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_login_scan.freezed.dart';
part 'qr_login_scan.g.dart';

/// What `POST /auth/qr/{id}/scan` says about the browser asking to be signed
/// in (auth doc 3.20). The confirm screen must show both — it is what stops
/// someone handing you *their* code to scan.
@freezed
class QrLoginScan with _$QrLoginScan {
  const factory QrLoginScan({
    /// Fixed words like "Chrome on Windows"; null when the browser is unknown.
    String? deviceLabel,
    String? location,
    required DateTime expiresAt,
  }) = _QrLoginScan;

  factory QrLoginScan.fromJson(Map<String, dynamic> json) =>
      _$QrLoginScanFromJson(json);
}

/// The id inside a web sign-in QR code, or null for anything else. The web
/// encodes exactly `nowa://qr-login?id=<id>`; any other text is not ours and
/// must never reach the server as an id.
String? qrLoginIdFrom(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'nowa' || uri.host != 'qr-login') {
    return null;
  }
  final id = uri.queryParameters['id'];
  if (id == null || !RegExp(r'^[A-Za-z0-9_-]{16,64}$').hasMatch(id)) {
    return null;
  }
  return id;
}
