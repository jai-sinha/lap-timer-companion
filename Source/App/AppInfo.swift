//
//  AppInfo.swift
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


import Foundation
import ConnectIQ

class AppInfo: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let name: String
    let appUUIDString: String
    let deviceUUIDString: String
    var status: IQAppStatus?
    var app: IQApp

    init(name: String, iqApp: IQApp) {
        self.name = name
        self.appUUIDString = iqApp.uuid.uuidString
        self.deviceUUIDString = iqApp.device.uuid.uuidString
        self.app = iqApp
        self.status = nil
        super.init()
    }
    
    func updateStatus(completion: @escaping (IQAppStatus?) -> Void) {
        // Log device and app state before status check
        let deviceName = app.device.friendlyName ?? "Unknown Device"
        let deviceStatus = ConnectIQ.sharedInstance().getDeviceStatus(app.device)
        let appUUID = app.uuid.uuidString
        print("[AppInfo] Checking status for app \(name) (UUID: \(appUUID)) on device \(deviceName) (status: \(deviceStatus.rawValue))")
        
        // Check if device is connected
        if deviceStatus != .connected {
            print("[AppInfo] Device \(deviceName) is not connected. Cannot check app status.")
            completion(nil)
            return
        }
        
        ConnectIQ.sharedInstance().getAppStatus(self.app) { status in
            if let status = status {
                print("[AppInfo] Got status for app \(self.name) on device \(deviceName): installed=\(status.isInstalled), version=\(status.version)")
            } else {
                print("[AppInfo] Failed to get status for app \(self.name) on device \(deviceName)")
            }
            self.status = status
            completion(status)
        }
    }
    
    required convenience init?(coder: NSCoder) {
        guard
            let name = coder.decodeObject(of: NSString.self, forKey: "name") as String?,
            let appUUIDString = coder.decodeObject(of: NSString.self, forKey: "appUUIDString") as String?,
            let deviceUUIDString = coder.decodeObject(of: NSString.self, forKey: "deviceUUIDString") as String?
        else {
            return nil
        }

        // Reconstruct IQApp from UUIDs and device
        guard
            let appUUID = UUID(uuidString: appUUIDString),
            let deviceUUID = UUID(uuidString: deviceUUIDString),
            let device = DeviceManager.sharedInstance.devices.first(where: { $0.uuid == deviceUUID })
        else {
            return nil
        }

        guard let iqApp = IQApp(uuid: appUUID, store: appUUID, device: device) else { return nil }
        self.init(name: name, iqApp: iqApp)
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(appUUIDString, forKey: "appUUIDString")
        coder.encode(deviceUUIDString, forKey: "deviceUUIDString")
    }
}
