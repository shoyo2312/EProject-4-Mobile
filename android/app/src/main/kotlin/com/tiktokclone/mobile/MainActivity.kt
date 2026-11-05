package com.tiktokclone.mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Share to one named app (Zalo, Messenger...) instead of the system
        // chooser. Answers false when that app is not installed, so Dart can
        // fall back to the chooser. Read by lib/core/utils/app_share.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tiktok_mobile/share")
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text") ?: ""
                when (call.method) {
                    "shareToPackage" -> {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            setPackage(call.argument<String>("package"))
                        }
                        result.success(tryStart(intent))
                    }
                    "shareToSms" -> {
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")).apply {
                            putExtra("sms_body", text)
                        }
                        result.success(tryStart(intent))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Starting and catching needs no <queries> entry, unlike resolveActivity.
    private fun tryStart(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }
}
