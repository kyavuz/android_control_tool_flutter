package com.example.brightness_slider

import android.content.ContentResolver
import android.provider.Settings
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "android/settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAutoBrightness" -> {
                    val resolver: ContentResolver = contentResolver
                    val mode = Settings.System.getInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, 0)
                    result.success(mode)
                }
                "setAutoBrightness" -> {
                    val resolver: ContentResolver = contentResolver
                    val mode = call.arguments as Int
                    try {
                        val success = Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, mode)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to change brightness mode", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
