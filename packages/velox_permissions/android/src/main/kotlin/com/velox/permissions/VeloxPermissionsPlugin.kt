package com.velox.permissions

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class VeloxPermissionsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var pendingPermissions: List<String>? = null
    private var pendingPermissionKeys: List<String>? = null

    companion object {
        private const val CHANNEL_NAME = "com.velox.permissions/method"
        private const val REQUEST_CODE = 9000
        private const val REQUEST_CODE_MULTIPLE = 9001

        private fun mapPermissionToAndroid(permission: String): String? {
            return when (permission) {
                "camera" -> Manifest.permission.CAMERA
                "microphone" -> Manifest.permission.RECORD_AUDIO
                "location" -> Manifest.permission.ACCESS_FINE_LOCATION
                "locationAlways" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION
                    } else {
                        Manifest.permission.ACCESS_FINE_LOCATION
                    }
                }
                "storage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        Manifest.permission.READ_MEDIA_IMAGES
                    } else {
                        Manifest.permission.READ_EXTERNAL_STORAGE
                    }
                }
                "photos" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        Manifest.permission.READ_MEDIA_IMAGES
                    } else {
                        Manifest.permission.READ_EXTERNAL_STORAGE
                    }
                }
                "contacts" -> Manifest.permission.READ_CONTACTS
                "calendar" -> Manifest.permission.READ_CALENDAR
                "notifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        Manifest.permission.POST_NOTIFICATIONS
                    } else {
                        null
                    }
                }
                "phone" -> Manifest.permission.READ_PHONE_STATE
                "sms" -> Manifest.permission.READ_SMS
                "bluetooth" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        Manifest.permission.BLUETOOTH_CONNECT
                    } else {
                        Manifest.permission.BLUETOOTH
                    }
                }
                "sensors" -> Manifest.permission.BODY_SENSORS
                else -> null
            }
        }

        private fun permissionStatusToString(
            activity: Activity,
            androidPermission: String,
            grantResult: Int? = null
        ): String {
            val granted = grantResult?.let { it == PackageManager.PERMISSION_GRANTED }
                ?: (ContextCompat.checkSelfPermission(activity, androidPermission)
                        == PackageManager.PERMISSION_GRANTED)

            if (granted) return "granted"

            val shouldShowRationale =
                ActivityCompat.shouldShowRequestPermissionRationale(activity, androidPermission)

            return if (shouldShowRationale) "denied" else "permanentlyDenied"
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "check" -> handleCheck(call, result)
            "request" -> handleRequest(call, result)
            "requestMultiple" -> handleRequestMultiple(call, result)
            "shouldShowRationale" -> handleShouldShowRationale(call, result)
            "openSettings" -> handleOpenSettings(result)
            else -> result.notImplemented()
        }
    }

    private fun handleCheck(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val permission = call.argument<String>("permission")
        if (permission == null) {
            result.error("INVALID_ARGS", "Permission argument is required", null)
            return
        }

        val androidPermission = mapPermissionToAndroid(permission)
        if (androidPermission == null) {
            // Permission not applicable on this API level (e.g., notifications < 33)
            result.success("granted")
            return
        }

        val granted = ContextCompat.checkSelfPermission(currentActivity, androidPermission) ==
                PackageManager.PERMISSION_GRANTED

        if (granted) {
            result.success("granted")
        } else {
            val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(
                currentActivity, androidPermission
            )
            if (shouldShowRationale) {
                result.success("denied")
            } else {
                result.success("denied")
            }
        }
    }

    private fun handleRequest(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val permission = call.argument<String>("permission")
        if (permission == null) {
            result.error("INVALID_ARGS", "Permission argument is required", null)
            return
        }

        val androidPermission = mapPermissionToAndroid(permission)
        if (androidPermission == null) {
            result.success("granted")
            return
        }

        val granted = ContextCompat.checkSelfPermission(currentActivity, androidPermission) ==
                PackageManager.PERMISSION_GRANTED

        if (granted) {
            result.success("granted")
            return
        }

        pendingResult = result
        pendingPermissions = listOf(androidPermission)
        pendingPermissionKeys = listOf(permission)

        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(androidPermission),
            REQUEST_CODE
        )
    }

    private fun handleRequestMultiple(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val permissions = call.argument<List<String>>("permissions")
        if (permissions == null || permissions.isEmpty()) {
            result.error("INVALID_ARGS", "Permissions argument is required", null)
            return
        }

        val androidPermissions = mutableListOf<String>()
        val permissionKeys = mutableListOf<String>()
        val resultMap = mutableMapOf<String, String>()

        for (permission in permissions) {
            val androidPermission = mapPermissionToAndroid(permission)
            if (androidPermission == null) {
                resultMap[permission] = "granted"
                continue
            }

            val granted = ContextCompat.checkSelfPermission(currentActivity, androidPermission) ==
                    PackageManager.PERMISSION_GRANTED

            if (granted) {
                resultMap[permission] = "granted"
            } else {
                androidPermissions.add(androidPermission)
                permissionKeys.add(permission)
            }
        }

        if (androidPermissions.isEmpty()) {
            result.success(resultMap)
            return
        }

        pendingResult = result
        pendingPermissions = androidPermissions
        pendingPermissionKeys = permissionKeys

        ActivityCompat.requestPermissions(
            currentActivity,
            androidPermissions.toTypedArray(),
            REQUEST_CODE_MULTIPLE
        )
    }

    private fun handleShouldShowRationale(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val permission = call.argument<String>("permission")
        if (permission == null) {
            result.error("INVALID_ARGS", "Permission argument is required", null)
            return
        }

        val androidPermission = mapPermissionToAndroid(permission)
        if (androidPermission == null) {
            result.success(false)
            return
        }

        val shouldShow = ActivityCompat.shouldShowRequestPermissionRationale(
            currentActivity, androidPermission
        )
        result.success(shouldShow)
    }

    private fun handleOpenSettings(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", currentActivity.packageName, null)
        }
        currentActivity.startActivity(intent)
        result.success(null)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != REQUEST_CODE && requestCode != REQUEST_CODE_MULTIPLE) {
            return false
        }

        val result = pendingResult ?: return false
        val currentActivity = activity ?: return false
        val keys = pendingPermissionKeys ?: return false

        pendingResult = null
        pendingPermissions = null
        pendingPermissionKeys = null

        if (requestCode == REQUEST_CODE) {
            if (grantResults.isNotEmpty()) {
                val status = permissionStatusToString(
                    currentActivity,
                    permissions[0],
                    grantResults[0]
                )
                result.success(status)
            } else {
                result.success("denied")
            }
        } else if (requestCode == REQUEST_CODE_MULTIPLE) {
            val resultMap = mutableMapOf<String, String>()

            for (i in permissions.indices) {
                val key = if (i < keys.size) keys[i] else continue
                val grantResult = if (i < grantResults.size) grantResults[i] else -1
                resultMap[key] = permissionStatusToString(
                    currentActivity,
                    permissions[i],
                    grantResult
                )
            }

            result.success(resultMap)
        }

        return true
    }
}
