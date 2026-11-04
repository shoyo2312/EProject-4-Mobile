import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Headers that tell auth-service which device a request comes from, so the
/// "Devices" screen can name it and the account's device limit (one
/// laptop/PC, one phone/tablet) can tell a phone from a PC.
///
/// - `User-Agent: NowaApp/1.0 (Android; Mobile)` — the server reads the
///   platform from here (`DeviceType`, `DeviceLabel` in auth-service).
/// - `Sec-CH-UA-Model` / `Sec-CH-UA-Platform-Version` — the same client hints
///   Chromium sends, so the server needs no app-specific parsing.
/// - `X-Device-Id` — a random id made once per install; not a credential.
///
/// Read once and cached. Never throws: without the plugin (tests, an
/// unsupported platform) only the id and a generic agent are sent.
class DeviceHeaders {
  DeviceHeaders({
    DeviceInfoPlugin? deviceInfo,
    FlutterSecureStorage? storage,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _storage = storage ?? const FlutterSecureStorage();

  static const appVersion = '1.0';
  static const _deviceIdKey = 'device_id';

  final DeviceInfoPlugin _deviceInfo;
  final FlutterSecureStorage _storage;
  Future<Map<String, String>>? _headers;

  Future<Map<String, String>> get headers => _headers ??= _read();

  Future<Map<String, String>> _read() async {
    // A browser owns its User-Agent and refuses to let a page set it.
    if (kIsWeb) return const {};

    final headers = <String, String>{};
    final id = await _deviceId();
    if (id != null) headers['X-Device-Id'] = id;

    final platform = await _platform();
    headers['User-Agent'] = 'NowaApp/$appVersion (${platform.agent})';
    if (platform.version != null) {
      headers['Sec-CH-UA-Platform-Version'] = '"${platform.version}"';
    }
    if (platform.model != null) {
      headers['Sec-CH-UA-Model'] = '"${_ascii(platform.model!)}"';
    }
    return headers;
  }

  Future<String?> _deviceId() async {
    try {
      final stored = await _storage.read(key: _deviceIdKey);
      if (stored != null) return stored;
      final random = Random.secure();
      final id = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
      await _storage.write(key: _deviceIdKey, value: id);
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<_Platform> _platform() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfo.androidInfo;
          return _Platform(
            'Android; Mobile',
            version: info.version.release,
            model: '${_capitalize(info.manufacturer)} ${info.model}',
          );
        case TargetPlatform.iOS:
          final info = await _deviceInfo.iosInfo;
          final isPad = info.model.toLowerCase().contains('ipad');
          return _Platform(
            isPad ? 'iPad; iPadOS' : 'iPhone; iOS',
            version: info.systemVersion,
            model: info.modelName.isNotEmpty ? info.modelName : info.utsname.machine,
          );
        case TargetPlatform.macOS:
          final info = await _deviceInfo.macOsInfo;
          return _Platform(
            'Macintosh; Mac OS X',
            version: '${info.majorVersion}.${info.minorVersion}',
            model: info.model,
          );
        case TargetPlatform.windows:
          // No version hint: the server reads Windows' hint the way Chromium
          // writes it (13+ = Windows 11), which is not the build number.
          return const _Platform('Windows NT');
        case TargetPlatform.linux:
          return const _Platform('X11; Linux');
        case TargetPlatform.fuchsia:
          return const _Platform('Fuchsia');
      }
    } catch (_) {
      return _Platform(defaultTargetPlatform.name);
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// HTTP header values must be Latin-1; a model name rarely is anything
  /// else, but one that is would make every request fail.
  static String _ascii(String s) =>
      s.replaceAll(RegExp(r'[^\x20-\x7E]'), '').replaceAll('"', '').trim();
}

class _Platform {
  const _Platform(this.agent, {this.version, this.model});

  final String agent;
  final String? version;
  final String? model;
}
