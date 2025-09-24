//
//  AppManager.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/19/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//

import Foundation
import ConnectIQ
import SwiftUI

protocol AppManagerDelegate: AnyObject {
    func appStatusChanged(_ appInfo: AppInfo)
    func appInstallationStatusChanged()
}

class AppManager: NSObject, ObservableObject, IQDeviceEventDelegate {
    @Published var pairedApps: [AppInfo] = []
    @Published var isChecking = false
    
    weak var delegate: AppManagerDelegate?
    static let sharedInstance = AppManager()
    
    private(set) var isConnectIQReady = false
    
    private override init() {
        super.init()
        // Initialize ConnectIQ
        ConnectIQ.sharedInstance().initialize(withUrlScheme: "laptimercompanion", uiOverrideDelegate: nil)
        // Register for device events for all known devices
        for device in DeviceManager.sharedInstance.devices {
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
        }
        restoreAppsFromFileSystem()
    }
    
    // MARK: - IQDeviceEventDelegate
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        // Optionally handle device status changes
        // You may want to refresh statuses or update UI here
        print("[Bluetooth Debug] Device status changed: \(device.friendlyName ?? "Unknown") -> \(status.rawValue)")
    }
    
    // MARK: - App Creation and Pairing
    
    /// Creates an IQApp instance for a specific device using the lap timer app UUID
    func createLapTimerApp(for device: IQDevice) -> IQApp? {
        guard let uuid = UUID(uuidString: kLapTimerAppUUID) else {
            return nil
        }
        // Use the new ConnectIQ SDK initializer
        return IQApp(uuid: uuid, store: uuid, device: device)
    }
    
    /// Pairs the lap timer app with all connected devices
    func pairLapTimerWithAllDevices() {
        let devices = DeviceManager.sharedInstance.devices
        for device in devices {
            pairLapTimerApp(with: device)
        }
    }
    
    /// Pairs the lap timer app with a specific device
    func pairLapTimerApp(with device: IQDevice) {
        let deviceName = device.friendlyName ?? "Unknown Device"
        guard let app = createLapTimerApp(for: device) else {
            return
        }
        // Check if this app is already paired
        let existingApp = pairedApps.first { appInfo in
            appInfo.app.device.uuid == device.uuid
        }
        if existingApp == nil {
            let appInfo = AppInfo(name: kLapTimerAppName, iqApp: app)
            pairedApps.append(appInfo)
            saveAppsToFileSystem()
            // Check the app status immediately
            checkAppStatus(appInfo: appInfo)
        }
    }
    
    // MARK: - App Status Management
    
    /// Checks the status of a specific app
    func checkAppStatus(appInfo: AppInfo) {
        guard let device = appInfo.app.device else { return }
        let connectionStatus = getConnectionStatus(for: device)
        isChecking = true
        // Only check status if device is connected
        guard connectionStatus == "Connected" else {
            isChecking = false
            appInfo.status = nil
            delegate?.appStatusChanged(appInfo)
            NotificationCenter.default.post(name: NSNotification.Name("AppManagerAppStatusChanged"), object: nil)
            return
        }
        ConnectIQ.sharedInstance().getAppStatus(appInfo.app) { [weak self] (appStatus: IQAppStatus?) in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.isChecking = false
                appInfo.status = appStatus
                strongSelf.delegate?.appStatusChanged(appInfo)
                NotificationCenter.default.post(name: NSNotification.Name("AppManagerAppStatusChanged"), object: nil)
            }
        }
    }
    
    /// Checks status for all paired apps
    func checkAllAppStatuses() {
        for appInfo in pairedApps {
            checkAppStatus(appInfo: appInfo)
        }
    }
    
    /// Refreshes app statuses and notifies UI
    func refreshAppStatuses() {
        checkAllAppStatuses()
        delegate?.appInstallationStatusChanged()
    }
    
    // MARK: - App Management
    
    /// Removes a paired app
    func removePairedApp(_ appInfo: AppInfo) {
        if let index = pairedApps.firstIndex(where: { $0.app.device.uuid == appInfo.app.device.uuid }) {
            pairedApps.remove(at: index)
            saveAppsToFileSystem()
        }
    }
    
    /// Gets app info for a specific device
    func getAppInfo(for device: IQDevice) -> AppInfo? {
        return pairedApps.first { $0.app.device.uuid == device.uuid }
    }
    
    /// Checks if the lap timer app is installed on any device
    func isLapTimerInstalledAnywhere() -> Bool {
        return pairedApps.contains { appInfo in
            appInfo.status?.isInstalled == true
        }
    }
    
    /// Gets all devices with the lap timer app installed
    func getDevicesWithLapTimerInstalled() -> [IQDevice] {
        return pairedApps.compactMap { appInfo in
            if appInfo.status?.isInstalled == true {
                return appInfo.app.device
            }
            return nil
        }
    }
    
    // MARK: - Persistence
    
    func saveAppsToFileSystem() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: pairedApps, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: self.appsFilePath()))
        } catch {
            print("Failed to save apps: \(error)")
        }
    }
    
    func restoreAppsFromFileSystem() {
        let filePath = self.appsFilePath()
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            guard let restoredApps = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, AppInfo.self], from: data) as? [AppInfo] else {
                return
            }
            
            pairedApps = restoredApps
            
            // Refresh statuses for restored apps
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAllAppStatuses()
            }
        } catch {
            print("Error restoring apps: \(error)")
            pairedApps.removeAll()
        }
    }
    
    private func appsFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let appSupportDirectory = URL(fileURLWithPath: paths[0])
        let dirExists = (try? appSupportDirectory.checkResourceIsReachable()) ?? false
        if !dirExists {
            do {
                try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                print("There was an error creating the directory \(appSupportDirectory) with error: \(error)")
            }
        }
        return appSupportDirectory.appendingPathComponent(kAppsFileName).path
    }
}

// MARK: - Convenience Extensions

extension AppManager {
    /// Automatically pairs lap timer app when new devices are added
    func handleNewDevicesAdded() {
        pairLapTimerWithAllDevices()
    }
    
    /// Returns a user-friendly status string for an app
    func getStatusString(for appInfo: AppInfo) -> String {
        if let status = appInfo.status {
            if status.isInstalled {
                return "Installed (v\(status.version))"
            } else {
                return "Not installed"
            }
        } else {
            let connectionStatus = getConnectionStatus(for: appInfo.app.device)
            switch connectionStatus {
            case "Connected":
                return "Checking status..."
            case "Bluetooth Not Ready":
                return "Bluetooth not ready"
            case "Not Connected":
                return "Device not connected"
            case "Not Found":
                return "Device not found"
            case "Invalid Device":
                return "Invalid device"
            default:
                return "Status unavailable"
            }
        }
    }
    
    /// Returns the connection status for a device
    func getConnectionStatus(for device: IQDevice) -> String {
        if !isConnectIQReady {
            return "Bluetooth Not Ready"
        }
        switch ConnectIQ.sharedInstance().getDeviceStatus(device) {
        case .connected:
            return "Connected"
        case .notConnected:
            return "Not Connected"
        case .notFound:
            return "Not Found"
        case .invalidDevice:
            return "Invalid Device"
        case .bluetoothNotReady:
            return "Bluetooth Not Ready"
        @unknown default:
            return "Unknown"
        }
    }
    
    // Helper to log detailed device info
    private func logDeviceInfo(_ device: IQDevice) {}
    private func logAllPairedDevices() {}
}
