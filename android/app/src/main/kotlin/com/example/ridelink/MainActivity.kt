package com.example.ridelink

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ridelink/config")
            .setMethodCallHandler { call, result ->
                if (call.method == "hasMapsKey") {
                    result.success(!readMapsKey().isNullOrBlank())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readMapsKey(): String? = try {
        val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        info.metaData?.getString("com.google.android.geo.API_KEY")
    } catch (e: Exception) {
        null
    }
}
