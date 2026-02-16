import Flutter
import UIKit

public class VeloxDevicePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.velox.device/method",
            binaryMessenger: registrar.messenger()
        )
        let instance = VeloxDevicePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDeviceInfo":
            result(getDeviceInfo())
        case "getScreenInfo":
            result(getScreenInfo())
        case "getBatteryInfo":
            result(getBatteryInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        let model = device.model
        let manufacturer = "Apple"
        let osVersion = device.systemVersion

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        let deviceType: String
        if device.userInterfaceIdiom == .pad {
            deviceType = "tablet"
        } else {
            deviceType = "phone"
        }

        return [
            "model": model,
            "manufacturer": manufacturer,
            "osVersion": osVersion,
            "appVersion": appVersion,
            "deviceType": deviceType,
        ]
    }

    private func getScreenInfo() -> [String: Any] {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale

        return [
            "width": Double(bounds.width * scale),
            "height": Double(bounds.height * scale),
            "pixelRatio": Double(scale),
        ]
    }

    private func getBatteryInfo() -> [String: Any] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let level = device.batteryLevel >= 0 ? Double(device.batteryLevel) : 0.0

        let state: String
        switch device.batteryState {
        case .charging:
            state = "charging"
        case .unplugged:
            state = "discharging"
        case .full:
            state = "full"
        case .unknown:
            state = "unknown"
        @unknown default:
            state = "unknown"
        }

        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        return [
            "level": level,
            "state": state,
            "isLowPower": isLowPower,
        ]
    }
}
