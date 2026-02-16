import Flutter
import Network

public class VeloxConnectivityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.velox.connectivity.monitor")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = VeloxConnectivityPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "com.velox.connectivity/method",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: "com.velox.connectivity/event",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkConnectivity":
            checkConnectivity(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startMonitoring()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopMonitoring()
        self.eventSink = nil
        return nil
    }

    private func checkConnectivity(result: @escaping FlutterResult) {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            monitor.cancel()
            let info = self?.pathToMap(path) ?? [
                "status": "unknown",
                "type": "unknown",
                "isOnline": false,
            ]
            DispatchQueue.main.async {
                result(info)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func startMonitoring() {
        stopMonitoring()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let info = self?.pathToMap(path) ?? [:]
            DispatchQueue.main.async {
                self?.eventSink?(info)
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }

    private func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    private func pathToMap(_ path: NWPath) -> [String: Any] {
        let isOnline = path.status == .satisfied
        let type: String
        if path.usesInterfaceType(.wifi) {
            type = "wifi"
        } else if path.usesInterfaceType(.cellular) {
            type = "mobile"
        } else if path.usesInterfaceType(.wiredEthernet) {
            type = "ethernet"
        } else if path.usesInterfaceType(.loopback) {
            type = "unknown"
        } else if path.usesInterfaceType(.other) {
            type = "unknown"
        } else {
            type = "none"
        }

        return [
            "status": isOnline ? "connected" : "disconnected",
            "type": type,
            "isOnline": isOnline,
        ]
    }
}
