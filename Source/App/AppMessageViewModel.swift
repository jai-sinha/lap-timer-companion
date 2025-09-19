//
//  AppMessageViewModel.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//

import SwiftUI

class AppMessageViewModel: ObservableObject, AppManagerDelegate {
    @Published var tableEntries: [TableEntry]
    @Published var logMessages: [String]
    @Published var pairedApps: [AppInfo] = []
    
    init(tableEntries: [TableEntry] = [], logMessages: [String] = []) {
        self.tableEntries = tableEntries
        self.logMessages = logMessages
        
        // Set up as delegate for app manager
        AppManager.sharedInstance.delegate = self
        self.pairedApps = AppManager.sharedInstance.pairedApps
    }
    
    func addLog(_ message: String) {
        logMessages.append(message)
        while logMessages.count > kMaxLogMessages {
            logMessages.removeFirst()
        }
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
