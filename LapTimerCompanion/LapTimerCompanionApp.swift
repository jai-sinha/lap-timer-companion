//
//  LapTimerCompanionApp.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import SwiftUI
import ConnectIQ

class AppDelegate: NSObject, UIApplicationDelegate, IQUIOverrideDelegate, IQDeviceEventDelegate {
    private var isExpectingGCMReturn = false
    private var gcmLaunchTime: Date?
    
    // MARK: - App State Keys for Persistence
    private let kExpectingGCMReturnKey = "ExpectingGCMReturn"
    private let kGCMLaunchTimeKey = "GCMLaunchTime"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ConnectIQ.sharedInstance().initialize(withUrlScheme: "laptimercompanion", uiOverrideDelegate: self)
        
        // Restore state in case app was terminated during GCM process
        restoreGCMState()
        
        // Check for devices after a longer delay to ensure UI is fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkForDevicesOnLaunch()
        }
        
        return true
    }
    
    // MARK: - App Lifecycle Methods for GCM Integration
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 App entered background - likely due to GCM launch")
        if isExpectingGCMReturn {
            print("📱 Background transition expected - GCM should now have control")
            // Persist state in case app gets terminated
            saveGCMState()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 App will enter foreground - check if returning from GCM")
        if isExpectingGCMReturn {
            if let launchTime = gcmLaunchTime, Date().timeIntervalSince(launchTime) < 3.0 {
                print("📱 WARNING: Returning too quickly from GCM - may indicate focus stealing issue")
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 App became active")
        // Don't immediately reset GCM expectation - let URL handling do it
        // This prevents premature cleanup if the app briefly becomes active
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("📱 App will resign active - GCM about to take focus")
        if isExpectingGCMReturn {
            // Save state before potentially losing focus permanently
            saveGCMState()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("📱 App will terminate - saving GCM state")
        if isExpectingGCMReturn {
            saveGCMState()
        }
    }
    
    // MARK: - GCM State Persistence
    
    private func saveGCMState() {
        UserDefaults.standard.set(isExpectingGCMReturn, forKey: kExpectingGCMReturnKey)
        if let gcmLaunchTime = gcmLaunchTime {
            UserDefaults.standard.set(gcmLaunchTime, forKey: kGCMLaunchTimeKey)
        }
        UserDefaults.standard.synchronize()
        print("📱 Saved GCM state: expecting=\(isExpectingGCMReturn)")
    }
    
    private func restoreGCMState() {
        isExpectingGCMReturn = UserDefaults.standard.bool(forKey: kExpectingGCMReturnKey)
        gcmLaunchTime = UserDefaults.standard.object(forKey: kGCMLaunchTimeKey) as? Date
        
        if isExpectingGCMReturn {
            print("📱 Restored GCM state: expecting return from previous session")
            // Check if too much time has passed (more than 5 minutes)
            if let launchTime = gcmLaunchTime, Date().timeIntervalSince(launchTime) > 300 {
                print("📱 GCM launch too old, clearing state")
                clearGCMState()
            }
        }
    }
    
    private func clearGCMState() {
        isExpectingGCMReturn = false
        gcmLaunchTime = nil
        UserDefaults.standard.removeObject(forKey: kExpectingGCMReturnKey)
        UserDefaults.standard.removeObject(forKey: kGCMLaunchTimeKey)
        UserDefaults.standard.synchronize()
        print("📱 Cleared GCM state")
    }
    
    // Check if devices exist and show setup popup if none found
    private func checkForDevicesOnLaunch() {
        let hasDevices = DatabaseManager.shared.hasStoredDevices()
        
        if !hasDevices {
            showDeviceSetupPopup()
        }
    }
    
    private func showDeviceSetupPopup() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Connect Your Garmin Device",
                message: "To get started with LapTimer Companion, you'll need to connect your Garmin device. This will allow you to sync lap times and track data between your device and this app.\n\nNote: This will open Garmin Connect Mobile where you can select your devices.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Connect Device", style: .default) { _ in
                print("📱 User tapped Connect Device - launching GCM")
                self.isExpectingGCMReturn = true
                self.gcmLaunchTime = Date()
                
                // Save state immediately before launching GCM
                self.saveGCMState()
                
                // Add a small delay before launching to ensure UI is stable
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    ConnectIQ.sharedInstance().showDeviceSelection()
                    print("📱 showDeviceSelection() called - app should now go to background")
                }
            })
            
            alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel))
            
            // Get the top-most view controller to present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // Handle URL opening for device selection response from GCM - using both old and new methods
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return handleIncomingURL(url: url, sourceApplication: sourceApplication)
    }
    
    // Also implement the newer iOS URL handling method
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[.sourceApplication] as? String
        return handleIncomingURL(url: url, sourceApplication: sourceApplication)
    }
    
    private func handleIncomingURL(url: URL, sourceApplication: String?) -> Bool {
        print("📱 App opened with URL: \(url)")
        print("📱 Source application: \(sourceApplication ?? "unknown")")
        print("📱 URL scheme: \(url.scheme ?? "none")")
        print("📱 URL query: \(url.query ?? "none")")
        print("📱 Full URL: \(url.absoluteString)")
        
        // Check if this is a GCM return
        if url.scheme == "laptimercompanion" {
            if sourceApplication == "com.garmin.connectmobile" {
                print("📱 Confirmed GCM return")
                if isExpectingGCMReturn {
                    print("📱 Received expected return from GCM")
                    clearGCMState()
                }
                
                // Process the device selection response
                processDeviceSelectionResponse(url: url, sourceApplication: sourceApplication)
                return true
            } else {
                print("📱 URL from different source: \(sourceApplication ?? "unknown")")
                // Still try to process in case sourceApplication is nil
                if isExpectingGCMReturn {
                    print("📱 Processing URL anyway since expecting GCM return")
                    processDeviceSelectionResponse(url: url, sourceApplication: sourceApplication)
                    clearGCMState()
                    return true
                }
            }
        }
        
        print("📱 URL not processed - scheme: \(url.scheme ?? "none"), expecting GCM: \(isExpectingGCMReturn)")
        return false
    }
    
    private func processDeviceSelectionResponse(url: URL, sourceApplication: String?) {
        if url.scheme == "laptimercompanion" && sourceApplication == "com.garmin.connectmobile" {
            if let devices = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url) {
                print("📱 Parsed \(devices.count) devices from GCM")
                
                // Convert devices array to dictionary and save to database
                var deviceDict: [String: IQDevice] = [:]
                for deviceObj in devices {
                    if let device = deviceObj as? IQDevice,
                       let uuid = device.uuid {
                        deviceDict[uuid.uuidString] = device
                        print("📱 Added device: \(uuid.uuidString)")
                        
                        // Register for device events as per documentation
                        ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
                    }
                }
                
                // Save to database - this automatically clears old devices per documentation
                DatabaseManager.shared.saveDevices(deviceDict)
                
                // Notify the app that devices were updated
                NotificationCenter.default.post(name: NSNotification.Name("ConnectIQDevicesUpdated"), object: devices)
                
                // Show success message
                let alert = UIAlertController(
                    title: "Device Connected!",
                    message: "Successfully connected \(devices.count) Garmin device(s).",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(alert, animated: true)
                }
            } else {
                print("📱 Failed to parse devices from URL")
                print("📱 This might be expected if user cancelled device selection")
            }
        } else {
            print("📱 URL scheme or source application mismatch")
            print("📱 Expected scheme: laptimercompanion, got: \(url.scheme ?? "none")")
            print("📱 Expected source: com.garmin.connectmobile, got: \(sourceApplication ?? "none")")
        }
    }
    
    // Add method to retrieve stored devices from database
    func getStoredDevices() -> [String: IQDevice] {
        return DatabaseManager.shared.fetchStoredDevices()
    }
    
    // MARK: - IQUIOverrideDelegate
    
    func needsToInstallConnectMobile() {
        // Show alert to user with choice to install GCM
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Garmin Connect Mobile Required",
                message: "This action requires Garmin Connect Mobile to be installed. Would you like to install it from the App Store?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Install", style: .default) { _ in
                ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Get the top-most view controller to present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - IQDeviceEventDelegate
    
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        print("📱 Device status changed: \(device.uuid?.uuidString ?? "unknown") - Status: \(status.rawValue)")
        
        // Notify the app that device status has changed
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("ConnectIQDeviceStatusChanged"),
                object: device,
                userInfo: ["status": status]
            )
        }
    }
}

@main
struct LapTimerCompanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
