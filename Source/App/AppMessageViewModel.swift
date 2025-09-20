//
//  AppMessageViewModel.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//

import SwiftUI
import ConnectIQ

class AppMessageViewModel: NSObject, ObservableObject, AppManagerDelegate, IQAppMessageDelegate {
    @Published var tableEntries: [TableEntry]
    @Published var logMessages: [String]
    @Published var pairedApps: [AppInfo] = []
    
    // The currently selected app for messaging
    @Published var selectedAppInfo: AppInfo? {
        didSet {
            unregisterForMessages()
            if let appInfo = selectedAppInfo {
                registerForMessages(appInfo: appInfo)
            }
        }
    }
    
    init(tableEntries: [TableEntry] = [], logMessages: [String] = [], selectedAppInfo: AppInfo? = nil) {
        self.tableEntries = tableEntries
        self.logMessages = logMessages
        self.selectedAppInfo = selectedAppInfo
        super.init()
        // Set up as delegate for app manager
        AppManager.sharedInstance.delegate = self
        self.pairedApps = AppManager.sharedInstance.pairedApps
        if let appInfo = selectedAppInfo {
            registerForMessages(appInfo: appInfo)
        }
    }
    
    deinit {
        unregisterForMessages()
    }
    
    func addLog(_ message: String) {
        logMessages.append(message)
        while logMessages.count > kMaxLogMessages {
            logMessages.removeFirst()
        }
    }
    
    // MARK: - Connect IQ Messaging
    
    func sendMessage(_ message: Any, to appInfo: AppInfo) {
        addLog("Sending message to \(appInfo.name): \(message)")
        ConnectIQ.sharedInstance().sendMessage(message, to: appInfo.app, progress: { [weak self] sent, total in
            let percent = 100 * Float(sent) / Float(total)
            self?.addLog(String(format: "Progress: %02.2f%% - %u/%u", percent, sent, total))
        }, completion: { [weak self] result in
            self?.addLog("Send message finished with result: \(result)")
        })
    }
    
    private func registerForMessages(appInfo: AppInfo) {
        ConnectIQ.sharedInstance().register(forAppMessages: appInfo.app, delegate: self)
        addLog("Registered for messages from \(appInfo.name)")
    }
    
    private func unregisterForMessages() {
        if let appInfo = selectedAppInfo {
            ConnectIQ.sharedInstance().unregister(forAppMessages: appInfo.app, delegate: self)
            addLog("Unregistered for messages from \(appInfo.name)")
        }
    }
    
    // MARK: - IQAppMessageDelegate
    func receivedMessage(_ message: Any, from app: IQApp) {
        addLog("Received message from app: \(app): \(message)")
    }
    
    // MARK: - App Management Methods
    
    /// Manually trigger app pairing with all devices
    func pairAppsWithAllDevices() {
        addLog("Starting app pairing with all connected devices...")
        AppManager.sharedInstance.pairLapTimerWithAllDevices()
    }
    
    /// Check status of all paired apps
    func refreshAppStatuses() {
        addLog("Checking status of all paired apps...")
        AppManager.sharedInstance.checkAllAppStatuses()
    }
    
    /// Get status string for display
    func getAppStatusString(for appInfo: AppInfo) -> String {
        return AppManager.sharedInstance.getStatusString(for: appInfo)
    }
    
    // MARK: - AppManagerDelegate
    
    func appStatusChanged(_ appInfo: AppInfo) {
        // Update the published array to trigger UI updates
        DispatchQueue.main.async {
            self.pairedApps = AppManager.sharedInstance.pairedApps
            
            let statusString = self.getAppStatusString(for: appInfo)
            let logMessage = "\(appInfo.name) on \(appInfo.app.device.friendlyName): \(statusString)"
            self.addLog(logMessage)
        }
    }
    
    func appInstallationStatusChanged() {
        DispatchQueue.main.async {
            self.pairedApps = AppManager.sharedInstance.pairedApps
            self.addLog("App installation status updated")
        }
    }
}
