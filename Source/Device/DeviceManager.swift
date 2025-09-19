//
//  DeviceManager.swift
//  Garmin-ExampleApp-Swift
//  1/1/2017
//  Modified in 2025 by Jai Sinha
//
//  The following code is a fully-functional port of Garmin's iOS Example App
//  originally written in Objective-C:
//  https://developer.garmin.com/connect-iq/sdk/
//
//  More details on the Connect IQ iOS SDK can be found at:
//  https://developer.garmin.com/connect-iq/developer-tools/ios-sdk-guide/
//
//  MIT License
//
//  Copyright (c) 2017 Doug Williams - dougw@igudo.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import ConnectIQ
import UIKit

let kDevicesFileName = "devices"

protocol DeviceManagerDelegate {
    func devicesChanged()
}

class DeviceManager: NSObject, IQDeviceEventDelegate {
    
    var devices = [IQDevice]()
    var delegate: DeviceManagerDelegate?
    
    static let sharedInstance = DeviceManager()
   
    private override init() {
        super.init()
    }
    
    func handleOpenURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard (options[.sourceApplication] as? String) == nil || (options[.sourceApplication] as? String) == IQGCMBundle else {
            return false
        }
        
        if url.scheme == ReturnURLScheme {
            let newDevices = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url)
            
            if let newDevices = newDevices, newDevices.count > 0 {
                // Instead of removing all devices, append only new ones
                for device in newDevices {
                    guard let device = device as? IQDevice else { continue }
                    
                    // Check if device is already in the list
                    if !self.devices.contains(where: { $0.uuid == device.uuid }) {
                        self.devices.append(device)
                        ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
                    }
                }
                
                self.saveDevicesToFileSystem()
                NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
                self.delegate?.devicesChanged()
                return true
            }
        }
        return false
    }
    
    func saveDevicesToFileSystem() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: devices, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: self.devicesFilePath()))
        } catch {
            print("Failed to save devices: \(error)")
        }
    }
    
    func restoreDevicesFromFileSystem() {
        let filePath = self.devicesFilePath()
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            guard let restoredDevices = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, IQDevice.self], from: data) as? [IQDevice] else {
                return
            }
            
            if restoredDevices.count > 0 {
                self.devices = restoredDevices
                
                // Re-register restored devices for status events
                for device in devices {
                    ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
            self.delegate?.devicesChanged()
        } catch {
            print("Error restoring devices: \(error)")
            self.devices.removeAll()
        }
    }
    
    func devicesFilePath() -> String {
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
        return appSupportDirectory.appendingPathComponent(kDevicesFileName).path
    }
    
    func refreshAllDeviceStatuses() {
        NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
    }
    
    // MARK: - IQDeviceEventDelegate
    
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
            self.delegate?.devicesChanged()
            
            // Automatically pair lap timer app with newly connected devices
            if status == .connected {
                AppManager.sharedInstance.pairLapTimerApp(with: device)
            }
        }
    }
    
    // MARK: - App Integration
    
    /// Triggers app pairing for all currently managed devices
    func pairAppsWithAllDevices() {
        AppManager.sharedInstance.pairLapTimerWithAllDevices()
    }
    
    func removeDevice(_ device: IQDevice) {
        if let index = devices.firstIndex(where: { $0.uuid == device.uuid }) {
            // Properly unregister device events with the delegate parameter
            ConnectIQ.sharedInstance().unregister(forDeviceEvents: device, delegate: self)
            devices.remove(at: index)
            saveDevicesToFileSystem()
            NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
            delegate?.devicesChanged()
        }
    }
}
