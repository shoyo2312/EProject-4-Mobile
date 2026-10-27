import 'package:tiktok_mobile/core/constants/env.dart';

const _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

/// Points a storage URL the backend built for itself at a host this device can
/// actually reach.
///
/// In local dev the backend signs URLs for `http://localhost:9000` (its
/// `MINIO_ENDPOINT`). On the Android emulator `localhost` is the emulator
/// itself, so the request fails before reaching MinIO. When the URL is on a
/// loopback host but the API is reached through some other host (`10.0.2.2`
/// on the emulator, a LAN IP on a phone over Wi-Fi), the API's host is the
/// machine running MinIO too — so swap it in and keep port and path.
///
/// Left alone: URLs on a real domain (production), and the case where the API
/// itself is on `localhost` (desktop, iOS simulator, or a USB phone with
/// `adb reverse`), where `localhost` already reaches the right machine.
///
/// Only safe for presigned POST-policy uploads and plain GETs: the POST policy
/// does not cover the host. A SigV4 query-signed URL would fail the signature.
String reachableFromDevice(String url, {String? apiBaseUrl}) {
  final target = Uri.tryParse(url);
  final api = Uri.tryParse(apiBaseUrl ?? Env.apiBaseUrl);
  if (target == null || api == null || api.host.isEmpty) return url;
  if (!_loopbackHosts.contains(target.host)) return url;
  if (_loopbackHosts.contains(api.host)) return url;
  return target.replace(host: api.host).toString();
}
