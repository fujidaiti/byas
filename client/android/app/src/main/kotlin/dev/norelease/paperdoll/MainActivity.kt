package dev.norelease.paperdoll

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val SECURE_STORAGE_CHANNEL = "dev.norelease.paperdoll/secure_storage"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                when (call.method) {
                    "read" -> result.success(TokenStore.read(applicationContext, key!!))
                    "write" -> {
                        TokenStore.write(applicationContext, key!!, call.argument<String>("value"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
