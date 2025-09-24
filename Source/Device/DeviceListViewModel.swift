//
//  AppMessageViewModel.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//

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
            let status = ConnectIQ.sharedInstance().getDeviceStatus(device)
            statuses[device.uuid] = status
            print("[Bluetooth Debug] Device: \(device.friendlyName ?? "Unknown") UUID: \(device.uuid?.uuidString ?? "nil") Status: \(status) (rawValue: \(status.rawValue))")
        }
        // Observe device changes
        NotificationCenter.default.addObserver(self, selector: #selector(devicesChanged), name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appStatusChanged), name: NSNotification.Name("AppManagerAppStatusChanged"), object: nil)
    }

    @objc func appStatusChanged() {
        devicesChanged()
    }
    
    @objc func devicesChanged() {
        DispatchQueue.main.async {
            self.devices = self.deviceManager.devices
            for device in self.devices {
                let status = ConnectIQ.sharedInstance().getDeviceStatus(device)
                self.statuses[device.uuid] = status
                print("[Bluetooth Debug] Device: \(device.friendlyName ?? "Unknown") UUID: \(device.uuid?.uuidString ?? "nil") Status: \(status) (rawValue: \(status.rawValue))")
            }
        }
    }
    
    func status(for device: IQDevice) -> IQDeviceStatus {
        let status = statuses[device.uuid] ?? .notConnected
        if status == .invalidDevice {
            // Force a fresh status check for invalid devices
            let freshStatus = ConnectIQ.sharedInstance().getDeviceStatus(device)
            if freshStatus != status {
                statuses[device.uuid] = freshStatus
                return freshStatus
            }
        }
        return status
    }
    
    func refreshStatuses() {
        print("DeviceListViewModel: manually refreshing statuses for \(devices.count) devices")
        for device in devices {
            let status = ConnectIQ.sharedInstance().getDeviceStatus(device)
            statuses[device.uuid] = status
        }
        
        // Also trigger a refresh from DeviceManager
        deviceManager.refreshAllDeviceStatuses()
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
    
    // Add debug method to clear saved devices
    func clearSavedDevices() {
        print("Clearing all saved devices for debugging...")
        deviceManager.devices.removeAll()
        devices.removeAll()
        statuses.removeAll()
        
        // Clear the saved file
        let filePath = deviceManager.devicesFilePath()
        try? FileManager.default.removeItem(atPath: filePath)
        
        NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
    }
    
    func removeDevice(at offsets: IndexSet) {
        for index in offsets {
            let device = devices[index]
            deviceManager.removeDevice(device)
        }
    }
}
