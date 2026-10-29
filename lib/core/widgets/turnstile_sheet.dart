import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Gets a Cloudflare Turnstile token for one call that mails a code.
///
/// A token is single-use, so every send asks for a fresh one. Screens reach
/// this through `turnstileVerifierProvider` so tests can swap in a fake.
abstract interface class TurnstileVerifier {
  /// Returns the token, or null when the user closed the challenge.
  Future<String?> solve(BuildContext context);
}

/// Shows the Turnstile widget in a WebView inside a bottom sheet. Most of the
/// time Cloudflare passes the device without any tap and the sheet closes on
/// its own; otherwise the user ticks the checkbox.
class WebViewTurnstileVerifier implements TurnstileVerifier {
  const WebViewTurnstileVerifier();

  @override
  Future<String?> solve(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _TurnstileSheet(),
    );
  }
}

/// Used with `USE_MOCK=true`, where no request reaches auth-service.
class FakeTurnstileVerifier implements TurnstileVerifier {
  const FakeTurnstileVerifier([this.token = 'mock-turnstile-token']);

  final String? token;

  @override
  Future<String?> solve(BuildContext context) async => token;
}

class _TurnstileSheet extends StatefulWidget {
  const _TurnstileSheet();

  @override
  State<_TurnstileSheet> createState() => _TurnstileSheetState();
}

class _TurnstileSheetState extends State<_TurnstileSheet> {
  WebViewController? _controller;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (Env.turnstileSiteKey.isEmpty) {
      _error = 'Verification is not configured. '
          'Run the app with --dart-define=TURNSTILE_SITE_KEY=<site key>.';
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('TurnstileBridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            // Only the main frame matters; a failed sub-resource inside the
            // Cloudflare iframe is retried by Cloudflare itself.
            if (error.isForMainFrame ?? false) {
              _fail('Could not load verification. Check your connection.');
            }
          },
        ),
      )
      ..loadHtmlString(_html(Env.turnstileSiteKey), baseUrl: Env.turnstileBaseUrl);
  }

  void _onMessage(JavaScriptMessage message) {
    final text = message.message;
    if (text.startsWith('token:')) {
      if (_done || !mounted) return;
      _done = true;
      Navigator.of(context).pop(text.substring('token:'.length));
    } else if (text.startsWith('error:')) {
      // 110200 = this hostname is not allowed for the site key.
      final code = text.substring('error:'.length);
      _fail(code == '110200'
          ? 'Verification failed: ${Env.turnstileBaseUrl} is not an allowed '
              'hostname for this site key.'
          : 'Verification failed ($code). Please try again.');
    } else if (text == 'expired') {
      _fail('Verification expired. Please try again.');
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  void _retry() {
    setState(() => _error = null);
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Verify you're human",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('turnstile_close_button'),
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controller != null)
              SizedBox(height: 90, child: WebViewWidget(controller: controller)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              if (controller != null)
                TextButton(onPressed: _retry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

String _html(String siteKey) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; height: 100%; background: #fff; }
  body { display: flex; align-items: center; justify-content: center; }
</style>
<script>
  function onTurnstileLoad() {
    turnstile.render('#widget', {
      sitekey: ${jsonEncode(siteKey)},
      theme: 'light',
      callback: function (t) { TurnstileBridge.postMessage('token:' + t); },
      'error-callback': function (c) { TurnstileBridge.postMessage('error:' + c); return true; },
      'expired-callback': function () { TurnstileBridge.postMessage('expired'); }
    });
  }
</script>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad&render=explicit" async defer></script>
</head>
<body><div id="widget"></div></body>
</html>
''';
