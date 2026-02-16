package com.velox.device

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.util.DisplayMetrics
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VeloxDevicePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.velox.device/method")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getDeviceInfo" -> result.success(getDeviceInfo())
            "getScreenInfo" -> result.success(getScreenInfo())
            "getBatteryInfo" -> result.success(getBatteryInfo())
            else -> result.notImplemented()
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        val model = Build.MODEL ?: "Unknown"
        val manufacturer = Build.MANUFACTURER ?: "Unknown"
        val osVersion = Build.VERSION.RELEASE ?: "Unknown"

        val appVersion = try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(context.packageName, 0)
            }
            packageInfo.versionName ?: "Unknown"
        } catch (e: PackageManager.NameNotFoundException) {
            "Unknown"
        }

        val deviceType = determineDeviceType()

        return mapOf(
            "model" to model,
            "manufacturer" to manufacturer,
            "osVersion" to osVersion,
            "appVersion" to appVersion,
            "deviceType" to deviceType
        )
    }

    private fun determineDeviceType(): String {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getMetrics(displayMetrics)

        val widthDp = displayMetrics.widthPixels / displayMetrics.density
        val heightDp = displayMetrics.heightPixels / displayMetrics.density
        val smallestWidthDp = minOf(widthDp, heightDp)

        return if (smallestWidthDp >= 600) "tablet" else "phone"
    }

    private fun getScreenInfo(): Map<String, Any> {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getRealMetrics(displayMetrics)

        return mapOf(
            "width" to displayMetrics.widthPixels.toDouble(),
            "height" to displayMetrics.heightPixels.toDouble(),
            "pixelRatio" to displayMetrics.density.toDouble()
        )
    }

    private fun getBatteryInfo(): Map<String, Any> {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, intentFilter)

        val level = batteryStatus?.let { intent ->
            val lvl = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (lvl >= 0 && scale > 0) lvl.toDouble() / scale.toDouble() else 0.0
        } ?: 0.0

        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val state = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "notCharging"
            else -> "unknown"
        }

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val isLowPower = powerManager.isPowerSaveMode

        return mapOf(
            "level" to level,
            "state" to state,
            "isLowPower" to isLowPower
        )
    }
}
