//
//  TrackConfigurationView.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import SwiftUI

struct TrackConfigurationView: View {
    @Binding var latitude: String
    @Binding var longitude: String
    @Binding var showCoordinateInput: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track Configuration")
                .font(.headline)
            
            Button("Set Start/Finish Line Coordinates") {
                showCoordinateInput = true
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            if !latitude.isEmpty && !longitude.isEmpty {
                Text("Start/Finish: \(latitude), \(longitude)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
