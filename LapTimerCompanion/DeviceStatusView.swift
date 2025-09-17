//
//  DeviceStatusView.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/17/25.
//

import SwiftUI

struct DeviceStatusView: View {
    @State private var hasDevices = false
    @State private var deviceCount = 0
    
    var body: some View {
        HStack {
            Image(systemName: hasDevices ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .foregroundColor(hasDevices ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hasDevices ? "Garmin Device Connected" : "No Device Connected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if hasDevices && deviceCount > 0 {
                    Text("\(deviceCount) device\(deviceCount == 1 ? "" : "s") paired")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap to connect a device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(hasDevices ? "Manage" : "Connect") {
                // Trigger device selection
                ConnectIQ.sharedInstance().showDeviceSelection()
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(hasDevices ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            checkDeviceStatus()
            
            // Listen for device updates
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ConnectIQDevicesUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                checkDeviceStatus()
            }
        }
    }
    
    private func checkDeviceStatus() {
        hasDevices = DatabaseManager.shared.hasStoredDevices()
        // Since we can't reconstruct actual devices, we'll count database entries
        // This is a simplified approach for the UI indicator
        let querySQL = "SELECT COUNT(*) FROM devices;"
        // We'll use a simple approach and just check if any devices exist
        deviceCount = hasDevices ? 1 : 0
    }
}

import ConnectIQ

#Preview {
    VStack(spacing: 20) {
        DeviceStatusView()
        DeviceStatusView()
    }
    .padding()
}