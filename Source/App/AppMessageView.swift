//
//  AppMessageView.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//


import SwiftUI

struct AppMessageView: View {
    @ObservedObject var viewModel: AppMessageViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Show latest received message
            if let latest = viewModel.latestReceivedMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Received Message:")
                        .font(.headline)
                    Text("Message: \(String(describing: latest.message))")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding([.top, .horizontal])
            }
            List(viewModel.tableEntries, id: \.label) { entry in
                Button(action: {
                    if let appInfo = viewModel.selectedAppInfo {
                        viewModel.sendMessage(entry.message, to: appInfo)
                    } else {
                        viewModel.addLog("No app selected for messaging.")
                    }
                }) {
                    Text(entry.label)
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: 300)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(viewModel.logMessages.enumerated()), id: \.offset) { index, msg in
                        Text(msg)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .background(Color(.systemGray6))
        }
    }
}

// Preview for SwiftUI canvas
#Preview {
    let entries = [TableEntry(label: "Test", message: "Hello" as AnyObject)]
    let vm = AppMessageViewModel(tableEntries: entries, logMessages: ["Log 1", "Log 2"])
    AppMessageView(viewModel: vm)
}
