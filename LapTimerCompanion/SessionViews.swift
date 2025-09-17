//
//  SessionViews.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import SwiftUI

struct SessionRowView: View {
    let session: Session
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.stats)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button("Delete") {
                    onDelete()
                }
                .foregroundColor(.red)
                .font(.caption)
            }
            
            Text(session.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let lapCount = session.lapCount,
               let bestLap = session.bestLapTime,
               let totalTime = session.totalTime {
                HStack {
                    Label("\(lapCount)", systemImage: "flag.circle")
                    Spacer()
                    Label("\(String(format: "%.1f", bestLap))s", systemImage: "timer")
                    Spacer()
                    Label("\(String(format: "%.1f", totalTime))s", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CoordinateInputView: View {
    @Binding var latitude: String
    @Binding var longitude: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Start/Finish Line Coordinates") {
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Save Coordinates") {
                        print("Coordinates saved:")
                        print("Start/Finish: \(latitude), \(longitude)")
                        dismiss()
                    }
                    .disabled(latitude.isEmpty || longitude.isEmpty)
                }
            }
            .navigationTitle("Track Coordinates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
