import SwiftUI
import ConnectIQ

@main
struct CommsApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Lap Timer Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)
                .padding(.bottom, 16)
            Divider()
            MessageView()
        }
    }
}
