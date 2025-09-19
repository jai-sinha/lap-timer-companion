import SwiftUI
import ConnectIQ

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                if !viewModel.connectedDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connected Device(s):")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        ForEach(viewModel.connectedDevices, id: \.uuid) { device in
                            Text(device.friendlyName)
                                .font(.headline)
                        }
                    }
                    .padding(.bottom, 8)
                }
                List(viewModel.devices, id: \.uuid) { device in
                    DeviceRowView(device: device, status: viewModel.status(for: device))
                }
            }
            .navigationTitle("Connect IQ Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showDeviceSelection()
                    }) {
                        Label("Find Devices", systemImage: "plus.circle")
                    }
                }
            }
            .onAppear {
                viewModel.refreshStatuses()
            }
        }
    }
}

struct DeviceRowView: View {
    let device: IQDevice
    let status: IQDeviceStatus
    
    var statusText: String {
        switch status {
        case .invalidDevice: return "Invalid Device"
        case .bluetoothNotReady: return "Bluetooth Off"
        case .notFound: return "Not Found"
        case .notConnected: return "Not Connected"
        case .connected: return "Connected"
        @unknown default: return "Unknown"
        }
    }
    var statusColor: Color {
        switch status {
        case .connected: return .green
        case .notConnected, .notFound, .bluetoothNotReady, .invalidDevice: return .red
        @unknown default: return .gray
        }
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.friendlyName)
                    .font(.headline)
                Text(device.modelName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(statusText)
                .foregroundColor(statusColor)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}
