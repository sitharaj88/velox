package com.velox.connectivity

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VeloxConnectivityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        methodChannel = MethodChannel(binding.binaryMessenger, "com.velox.connectivity/method")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.velox.connectivity/event")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        unregisterNetworkCallback()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkConnectivity" -> result.success(getConnectivityInfo())
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerNetworkCallback()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        unregisterNetworkCallback()
    }

    private fun getConnectivityInfo(): Map<String, Any> {
        val cm = connectivityManager ?: return mapOf(
            "status" to "unknown",
            "type" to "unknown",
            "isOnline" to false,
        )

        val network = cm.activeNetwork
        val capabilities = if (network != null) cm.getNetworkCapabilities(network) else null

        if (capabilities == null) {
            return mapOf(
                "status" to "disconnected",
                "type" to "none",
                "isOnline" to false,
            )
        }

        val isOnline = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

        val type = when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
            else -> "unknown"
        }

        return mapOf(
            "status" to if (isOnline) "connected" else "disconnected",
            "type" to type,
            "isOnline" to isOnline,
        )
    }

    private fun registerNetworkCallback() {
        val cm = connectivityManager ?: return
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                eventSink?.success(getConnectivityInfo())
            }

            override fun onLost(network: Network) {
                eventSink?.success(
                    mapOf(
                        "status" to "disconnected",
                        "type" to "none",
                        "isOnline" to false,
                    )
                )
            }

            override fun onCapabilitiesChanged(
                network: Network,
                capabilities: NetworkCapabilities
            ) {
                eventSink?.success(getConnectivityInfo())
            }
        }
        networkCallback = callback
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        cm.registerNetworkCallback(request, callback)
    }

    private fun unregisterNetworkCallback() {
        networkCallback?.let { connectivityManager?.unregisterNetworkCallback(it) }
        networkCallback = null
    }
}
