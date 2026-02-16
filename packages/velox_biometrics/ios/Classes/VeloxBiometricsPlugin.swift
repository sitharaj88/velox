import Flutter
import UIKit
import LocalAuthentication

public class VeloxBiometricsPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.velox.biometrics/method",
            binaryMessenger: registrar.messenger()
        )
        let instance = VeloxBiometricsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAvailability":
            checkAvailability(result: result)
        case "getAvailableBiometrics":
            getAvailableBiometrics(result: result)
        case "authenticate":
            authenticate(call: call, result: result)
        case "isDeviceSupported":
            isDeviceSupported(result: result)
        case "isEnrolled":
            isEnrolled(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkAvailability(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            result("available")
        } else {
            guard let laError = error as? LAError else {
                result("notSupported")
                return
            }

            switch laError.code {
            case .biometryNotAvailable:
                result("notSupported")
            case .biometryNotEnrolled:
                result("notEnrolled")
            case .biometryLockout:
                result("lockedOut")
            default:
                result("unavailable")
            }
        }
    }

    private func getAvailableBiometrics(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?

        // We need to call canEvaluatePolicy to populate biometryType
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        var biometrics: [String] = []

        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                biometrics.append("face")
            case .touchID:
                biometrics.append("fingerprint")
            case .none:
                break
            @unknown default:
                break
            }

            if #available(iOS 17.0, *) {
                if context.biometryType == .opticID {
                    biometrics = ["iris"]
                }
            }
        }

        result(biometrics)
    }

    private func authenticate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(
                [
                    "status": "error",
                    "biometricType": nil,
                    "errorMessage": "Invalid arguments",
                ] as [String: Any?]
            )
            return
        }

        let localizedReason = args["localizedReason"] as? String ?? "Authenticate"
        let biometricOnly = args["biometricOnly"] as? Bool ?? false

        let context = LAContext()
        let policy: LAPolicy = biometricOnly
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        context.evaluatePolicy(policy, localizedReason: localizedReason) { success, error in
            DispatchQueue.main.async {
                if success {
                    var biometricType: String? = nil
                    if #available(iOS 11.0, *) {
                        switch context.biometryType {
                        case .faceID:
                            biometricType = "face"
                        case .touchID:
                            biometricType = "fingerprint"
                        case .none:
                            break
                        @unknown default:
                            break
                        }

                        if #available(iOS 17.0, *) {
                            if context.biometryType == .opticID {
                                biometricType = "iris"
                            }
                        }
                    }

                    result(
                        [
                            "status": "success",
                            "biometricType": biometricType as Any,
                            "errorMessage": nil,
                        ] as [String: Any?]
                    )
                } else {
                    var status = "error"
                    var errorMessage: String? = error?.localizedDescription

                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel, .appCancel:
                            status = "cancelled"
                        case .biometryLockout:
                            status = "lockedOut"
                        case .authenticationFailed:
                            status = "failed"
                        default:
                            status = "error"
                        }
                    }

                    result(
                        [
                            "status": status,
                            "biometricType": nil,
                            "errorMessage": errorMessage as Any,
                        ] as [String: Any?]
                    )
                }
            }
        }
    }

    private func isDeviceSupported(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        if canEvaluate {
            result(true)
        } else {
            // Device is supported unless there's no hardware at all
            guard let laError = error as? LAError else {
                result(false)
                return
            }
            result(laError.code != .biometryNotAvailable)
        }
    }

    private func isEnrolled(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        result(canEvaluate)
    }
}
