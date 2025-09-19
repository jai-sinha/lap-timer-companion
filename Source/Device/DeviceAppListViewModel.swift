//
//  DeviceAppListViewModel.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//


import SwiftUI
import ConnectIQ

class DeviceAppListViewModel: ObservableObject {
    @Published var appInfos: [AppInfo] = []
    @Published var currentAppId: UUID?
    let device: IQDevice
    
    init(device: IQDevice) {
        self.device = device
        let loopbackApp = IQApp(uuid: UUID(uuidString: "0180e520-5f7e-11e4-9803-0800200c9a66"), store: UUID(), device: device)
        let stringApp = IQApp(uuid: UUID(uuidString: "a3421fee-d289-106a-538c-b9547ab12095"), store: UUID(), device: device)
        let gameApp = IQApp(uuid: UUID(uuidString: "3bc0423d-5f82-46bb-8396-e714f608232f"), store: UUID(uuidString: "8ecc61f6-541e-45e7-b227-278a39abefd8"), device: device)
        
        self.appInfos = [
            AppInfo(name: "Loopback Test App", iqApp: loopbackApp!),
            AppInfo(name: "String Test App", iqApp: stringApp!),
            AppInfo(name: "2048 App", iqApp: gameApp!)
        ]
        updateAllStatuses()
    }
    
    func updateAllStatuses() {
        let group = DispatchGroup()
        for appInfo in appInfos {
            group.enter()
            appInfo.updateStatus { _ in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.objectWillChange.send()
        }
    }
    
    func setCurrentAppId(_ id: UUID) {
        currentAppId = id
    }
    
    func installCurrentApp() {
        guard let id = currentAppId, let appInfo = appInfos.first(where: { $0.app.uuid == id }) else { return }
        ConnectIQ.sharedInstance().showStore(for: appInfo.app)
    }
}

struct DeviceAppListView: View {
    @ObservedObject var viewModel: DeviceAppListViewModel
    
    var body: some View {
        VStack {
            List(viewModel.appInfos, id: \.app.uuid) { appInfo in
                AppInfoRow(appInfo: appInfo)
                    .onTapGesture {
                        viewModel.setCurrentAppId(appInfo.app.uuid)
                    }
            }
            Button(action: {
                viewModel.installCurrentApp()
            }) {
                Text("Install Selected App")
            }
            .disabled(viewModel.currentAppId == nil || !(viewModel.appInfos.first(where: { $0.app.uuid == viewModel.currentAppId })?.status?.isInstalled == false))
            .padding()
        }
        .navigationTitle(viewModel.device.friendlyName)
    }
}

struct AppInfoRow: View {
    let appInfo: AppInfo
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(appInfo.name)
                    .font(.headline)
                if let status = appInfo.status {
                    if status.isInstalled {
                        Text("Installed (v\(status.version))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("Not installed")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Checking status...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}