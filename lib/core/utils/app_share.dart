import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// An app the share sheet can send a link straight to.
enum ShareApp {
  messages(null),
  zalo('com.zing.zalo'),
  messenger('com.facebook.orca'),
  instagram('com.instagram.android'),
  facebook('com.facebook.katana');

  const ShareApp(this.androidPackage);

  /// Null for [messages]: SMS goes to whichever app is the default.
  final String? androidPackage;
}

/// Sends text to other apps. On Android a named app is opened directly
/// (`MainActivity.kt`, channel `tiktok_mobile/share`); when it is not
/// installed, and on every other platform, the system share sheet opens
/// instead so the person can still pick something.
class AppShare {
  const AppShare._();

  static const _channel = MethodChannel('tiktok_mobile/share');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True when something was handed to another app (or, for the system
  /// sheet, when the platform says the person picked a target).
  static Future<bool> shareTo(ShareApp app, String text) async {
    if (_isAndroid) {
      try {
        final opened = app == ShareApp.messages
            ? await _channel.invokeMethod<bool>('shareToSms', {'text': text})
            : await _channel.invokeMethod<bool>('shareToPackage', {
                'text': text,
                'package': app.androidPackage,
              });
        if (opened ?? false) return true;
      } on PlatformException {
        // Fall through to the system sheet.
      } on MissingPluginException {
        // Same: an older native build without the channel.
      }
    }
    return shareWithSystem(text);
  }

  static Future<bool> shareWithSystem(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    // `unavailable` means the platform cannot tell — count it, the sheet
    // did open with the link in it.
    return result.status != ShareResultStatus.dismissed;
  }
}
