import SwiftUI

struct ContentView: View {
    @State private var sessions: [Session] = []
    @State private var showCoordinateInput = false
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome to Lap Timer Companion")
                    TrackConfigurationView(
                        latitude: $latitude,
                        longitude: $longitude,
                        showCoordinateInput: $showCoordinateInput
                    )
                    SessionsListView(sessions: $sessions)
                }
                .padding()
            }
            .navigationTitle("Lap Timer Companion")
            .onAppear {
                sessions = DatabaseManager.shared.fetchSessions()
            }
            .sheet(isPresented: $showCoordinateInput) {
                CoordinateInputView(
                    latitude: $latitude,
                    longitude: $longitude
                )
            }
        }
    }
}
