package com.velox.biometrics

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VeloxBiometricsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.velox.biometrics/method")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkAvailability" -> checkAvailability(result)
            "getAvailableBiometrics" -> getAvailableBiometrics(result)
            "authenticate" -> authenticate(call, result)
            "isDeviceSupported" -> isDeviceSupported(result)
            "isEnrolled" -> isEnrolled(result)
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        val biometricManager = BiometricManager.from(ctx)
        val status = biometricManager.canAuthenticate(BIOMETRIC_STRONG)

        val statusString = when (status) {
            BiometricManager.BIOMETRIC_SUCCESS -> "available"
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "notSupported"
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "unavailable"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "notEnrolled"
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "unavailable"
            else -> "notSupported"
        }

        result.success(statusString)
    }

    private fun getAvailableBiometrics(result: Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        val packageManager = ctx.packageManager
        val biometrics = mutableListOf<String>()

        if (packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) {
            biometrics.add("fingerprint")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)) {
                biometrics.add("face")
            }
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_IRIS)) {
                biometrics.add("iris")
            }
        }

        result.success(biometrics)
    }

    private fun authenticate(call: MethodCall, result: Result) {
        val currentActivity = activity

        if (currentActivity == null || currentActivity !is FragmentActivity) {
            result.error(
                "NO_ACTIVITY",
                "Activity not available or not a FragmentActivity",
                null
            )
            return
        }

        val localizedReason = call.argument<String>("localizedReason") ?: "Authenticate"
        val biometricOnly = call.argument<Boolean>("biometricOnly") ?: false

        val executor = ContextCompat.getMainExecutor(currentActivity)

        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(authResult)
                result.success(
                    mapOf(
                        "status" to "success",
                        "biometricType" to null,
                        "errorMessage" to null
                    )
                )
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                val status = when (errorCode) {
                    BiometricPrompt.ERROR_USER_CANCELED,
                    BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                    BiometricPrompt.ERROR_CANCELED -> "cancelled"
                    BiometricPrompt.ERROR_LOCKOUT,
                    BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "lockedOut"
                    else -> "error"
                }
                result.success(
                    mapOf(
                        "status" to status,
                        "biometricType" to null,
                        "errorMessage" to errString.toString()
                    )
                )
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                // Note: onAuthenticationFailed is called on each failed attempt
                // but does not end the authentication flow. The prompt stays open.
                // We do not call result.success here to avoid calling result twice.
            }
        }

        val biometricPrompt = BiometricPrompt(currentActivity, executor, callback)

        val promptInfoBuilder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(localizedReason)

        if (biometricOnly) {
            promptInfoBuilder
                .setAllowedAuthenticators(BIOMETRIC_STRONG)
                .setNegativeButtonText("Cancel")
        } else {
            promptInfoBuilder
                .setAllowedAuthenticators(BIOMETRIC_STRONG or DEVICE_CREDENTIAL)
        }

        try {
            biometricPrompt.authenticate(promptInfoBuilder.build())
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "status" to "error",
                    "biometricType" to null,
                    "errorMessage" to e.message
                )
            )
        }
    }

    private fun isDeviceSupported(result: Result) {
        val ctx = context ?: run {
            result.success(false)
            return
        }

        val biometricManager = BiometricManager.from(ctx)
        val canAuth = biometricManager.canAuthenticate(BIOMETRIC_STRONG)
        result.success(canAuth != BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE)
    }

    private fun isEnrolled(result: Result) {
        val ctx = context ?: run {
            result.success(false)
            return
        }

        val biometricManager = BiometricManager.from(ctx)
        val canAuth = biometricManager.canAuthenticate(BIOMETRIC_STRONG)
        result.success(canAuth == BiometricManager.BIOMETRIC_SUCCESS)
    }
}
