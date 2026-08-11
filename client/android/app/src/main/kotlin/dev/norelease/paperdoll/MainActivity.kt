package dev.norelease.paperdoll

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

private const val SECURE_STORAGE_CHANNEL = "dev.norelease.paperdoll/secure_storage"

class MainActivity : FlutterActivity() {
    // Main dispatcher, because a MethodChannel result must be answered on the platform
    // thread. SecureStorage's own work (DataStore I/O, Keystore) dispatches itself off it.
    private val channelScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURE_STORAGE_CHANNEL
        ).setMethodCallHandler { call, result ->
                channelScope.launch {
                    try {
                        val key = call.argument<String>("key")
                        when (call.method) {
                            "read" -> result.success(SecureStorage.read(applicationContext, key!!))
                            "write" -> {
                                val value = call.argument<String>("value")
                                SecureStorage.write(applicationContext, key!!, value)
                                result.success(null)
                            }

                            else -> result.notImplemented()
                        }
                    } catch (e: Exception) {
                        result.error("secure_storage_failed", e.message, null)
                    }
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channelScope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
