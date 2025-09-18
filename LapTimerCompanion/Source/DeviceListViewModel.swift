import Foundation
import ConnectIQ
import Combine

class DeviceListViewModel: ObservableObject {
    @Published var devices: [IQDevice] = []
    @Published var statuses: [UUID: IQDeviceStatus] = [:]
    private var deviceManager = DeviceManager.sharedInstance
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initial load
        self.devices = deviceManager.devices
        for device in devices {
            statuses[device.uuid] = ConnectIQ.sharedInstance().getDeviceStatus(device)
        }
        // Observe device changes
        NotificationCenter.default.addObserver(self, selector: #selector(devicesChanged), name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
    }
    
    @objc func devicesChanged() {
        DispatchQueue.main.async {
            self.devices = self.deviceManager.devices
            for device in self.devices {
                self.statuses[device.uuid] = ConnectIQ.sharedInstance().getDeviceStatus(device)
            }
        }
    }
    
    func status(for device: IQDevice) -> IQDeviceStatus {
        statuses[device.uuid] ?? .notConnected
    }
    
    func refreshStatuses() {
        for device in devices {
            statuses[device.uuid] = ConnectIQ.sharedInstance().getDeviceStatus(device)
        }
    }
    
    func openGCMApp() {
        ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
    }
    
    func showDeviceSelection() {
        ConnectIQ.sharedInstance().showDeviceSelection()
    }
    
    var connectedDevices: [IQDevice] {
        devices.filter { status(for: $0) == .connected }
    }
}
