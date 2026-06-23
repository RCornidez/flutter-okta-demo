package com.okta.trial_8077266

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.okta.trial_8077266/auth")
        channel!!.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(pendingLink)
                pendingLink = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingLink = intent.data?.takeIf { it.scheme == "com.okta.trial-8077266" }?.toString()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.data?.takeIf { it.scheme == "com.okta.trial-8077266" }?.toString() ?: return
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onLink", uri)
        } else {
            pendingLink = uri
        }
    }
}
