import Flutter
import UIKit
import AVFoundation
import Photos
import Contacts
import EventKit
import CoreLocation
import UserNotifications
import CoreBluetooth
import CoreMotion

public class VeloxPermissionsPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var locationResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.velox.permissions/method",
            binaryMessenger: registrar.messenger()
        )
        let instance = VeloxPermissionsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "check":
            handleCheck(call, result: result)
        case "request":
            handleRequest(call, result: result)
        case "requestMultiple":
            handleRequestMultiple(call, result: result)
        case "shouldShowRationale":
            // iOS does not have a rationale concept like Android
            result(false)
        case "openSettings":
            handleOpenSettings(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Check Permission

    private func handleCheck(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permission = args["permission"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Permission argument is required", details: nil))
            return
        }

        checkPermissionStatus(permission) { status in
            result(status)
        }
    }

    // MARK: - Request Permission

    private func handleRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permission = args["permission"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Permission argument is required", details: nil))
            return
        }

        requestPermission(permission) { status in
            result(status)
        }
    }

    // MARK: - Request Multiple

    private func handleRequestMultiple(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissions = args["permissions"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Permissions argument is required", details: nil))
            return
        }

        var resultMap: [String: String] = [:]
        let group = DispatchGroup()

        for permission in permissions {
            group.enter()
            requestPermission(permission) { status in
                resultMap[permission] = status
                group.leave()
            }
        }

        group.notify(queue: .main) {
            result(resultMap)
        }
    }

    // MARK: - Open Settings

    private func handleOpenSettings(result: @escaping FlutterResult) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            result(FlutterError(code: "UNAVAILABLE", message: "Cannot open settings", details: nil))
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { _ in
                result(nil)
            }
        } else {
            result(FlutterError(code: "UNAVAILABLE", message: "Cannot open settings", details: nil))
        }
    }

    // MARK: - Permission Status Checking

    private func checkPermissionStatus(_ permission: String, completion: @escaping (String) -> Void) {
        switch permission {
        case "camera":
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            completion(mapAVAuthorizationStatus(status))

        case "microphone":
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            completion(mapAVAuthorizationStatus(status))

        case "location":
            let status = CLLocationManager.authorizationStatus()
            completion(mapCLAuthorizationStatus(status, alwaysRequired: false))

        case "locationAlways":
            let status = CLLocationManager.authorizationStatus()
            completion(mapCLAuthorizationStatus(status, alwaysRequired: true))

        case "photos", "storage":
            if #available(iOS 14, *) {
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                completion(mapPHAuthorizationStatus(status))
            } else {
                let status = PHPhotoLibrary.authorizationStatus()
                completion(mapPHAuthorizationStatusLegacy(status))
            }

        case "contacts":
            let status = CNContactStore.authorizationStatus(for: .contacts)
            completion(mapCNAuthorizationStatus(status))

        case "calendar":
            let status = EKEventStore.authorizationStatus(for: .event)
            completion(mapEKAuthorizationStatus(status))

        case "notifications":
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    completion(self.mapUNAuthorizationStatus(settings.authorizationStatus))
                }
            }

        case "phone":
            // iOS does not have a runtime phone permission
            completion("granted")

        case "sms":
            // iOS does not have a runtime SMS permission
            completion("granted")

        case "bluetooth":
            if #available(iOS 13.1, *) {
                let status = CBManager.authorization
                completion(self.mapCBManagerAuthorization(status))
            } else {
                completion("granted")
            }

        case "sensors":
            if #available(iOS 11.0, *) {
                let status = CMMotionActivityManager.authorizationStatus()
                completion(mapCMAuthorizationStatus(status))
            } else {
                completion("granted")
            }

        default:
            completion("unknown")
        }
    }

    // MARK: - Permission Requesting

    private func requestPermission(_ permission: String, completion: @escaping (String) -> Void) {
        switch permission {
        case "camera":
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? "granted" : "denied")
                }
            }

        case "microphone":
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted ? "granted" : "denied")
                }
            }

        case "location":
            self.requestLocationPermission(always: false, completion: completion)

        case "locationAlways":
            self.requestLocationPermission(always: true, completion: completion)

        case "photos", "storage":
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        completion(self.mapPHAuthorizationStatus(status))
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        completion(self.mapPHAuthorizationStatusLegacy(status))
                    }
                }
            }

        case "contacts":
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted ? "granted" : "denied")
                }
            }

        case "calendar":
            if #available(iOS 17.0, *) {
                EKEventStore().requestFullAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted ? "granted" : "denied")
                    }
                }
            } else {
                EKEventStore().requestAccess(to: .event) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted ? "granted" : "denied")
                    }
                }
            }

        case "notifications":
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted ? "granted" : "denied")
                }
            }

        case "phone":
            completion("granted")

        case "sms":
            completion("granted")

        case "bluetooth":
            if #available(iOS 13.1, *) {
                let status = CBManager.authorization
                completion(self.mapCBManagerAuthorization(status))
            } else {
                completion("granted")
            }

        case "sensors":
            if #available(iOS 11.0, *) {
                let motionManager = CMMotionActivityManager()
                motionManager.queryActivityStarting(
                    from: Date(),
                    to: Date(),
                    to: .main
                ) { _, error in
                    if let error = error as NSError?,
                       error.domain == CMErrorDomain {
                        completion("denied")
                    } else {
                        completion("granted")
                    }
                    motionManager.stopActivityUpdates()
                }
            } else {
                completion("granted")
            }

        default:
            completion("unknown")
        }
    }

    // MARK: - Location Helper

    private func requestLocationPermission(always: Bool, completion: @escaping (String) -> Void) {
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        locationResult = { result in
            if let status = result as? String {
                completion(status)
            } else {
                completion("unknown")
            }
        }

        if always {
            locationManager?.requestAlwaysAuthorization()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let result = locationResult else { return }

        let status = CLLocationManager.authorizationStatus()

        if status == .notDetermined {
            // Still waiting for user response
            return
        }

        let statusString = mapCLAuthorizationStatus(status, alwaysRequired: false)
        result(statusString)

        locationResult = nil
        locationManager?.delegate = nil
        locationManager = nil
    }

    // MARK: - Status Mapping Helpers

    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func mapCLAuthorizationStatus(_ status: CLAuthorizationStatus, alwaysRequired: Bool) -> String {
        switch status {
        case .authorizedAlways:
            return "granted"
        case .authorizedWhenInUse:
            return alwaysRequired ? "denied" : "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    @available(iOS 14, *)
    private func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .limited:
            return "limited"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func mapPHAuthorizationStatusLegacy(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func mapCNAuthorizationStatus(_ status: CNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func mapEKAuthorizationStatus(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func mapUNAuthorizationStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    @available(iOS 13.1, *)
    private func mapCBManagerAuthorization(_ status: CBManagerAuthorization) -> String {
        switch status {
        case .allowedAlways:
            return "granted"
        case .denied:
            return "permanentlyDenied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    @available(iOS 11.0, *)
    private func mapCMAuthorizationStatus(_ status: CMAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }
}
