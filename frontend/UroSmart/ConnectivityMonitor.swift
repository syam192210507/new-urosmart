import Foundation
import Combine
import Network

class ConnectivityMonitor: ObservableObject {
    static let shared = ConnectivityMonitor()
    
    @Published var isOnline: Bool = false
    @Published var connectionType: ConnectionType = .none
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case none
        
        var description: String {
            switch self {
            case .wifi: return "WiFi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .none: return "No Connection"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .none
                }
                
                print("📡 Connectivity: \(self?.isOnline == true ? "Online" : "Offline") (\(self?.connectionType.description ?? ""))")
            }
        }
        
        monitor.start(queue: queue)
    }
}
