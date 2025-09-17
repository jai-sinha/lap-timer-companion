//
//  SessionsListView.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import SwiftUI

struct SessionsListView: View {
    @Binding var sessions: [Session]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Saved Sessions")
                    .font(.headline)
                Spacer()
                Button("Add Demo Session") {
                    addDemoSession()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
                .font(.caption)
            }
            
            if sessions.isEmpty {
                Text("No sessions saved yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(sessions) { session in
                        SessionRowView(session: session) {
                            deleteSession(session)
                        }
                    }
                }
            }
        }
    }
    
    private func addDemoSession() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let stats = "Demo session - \(formatter.string(from: Date()))"
        DatabaseManager.shared.insertSession(
            date: Date(),
            stats: stats,
            lapCount: Int.random(in: 5...20),
            bestLapTime: Double.random(in: 60...120),
            totalTime: Double.random(in: 300...1200)
        )
        sessions = DatabaseManager.shared.fetchSessions()
    }
    
    private func deleteSession(_ session: Session) {
        if let id = session.id {
            DatabaseManager.shared.deleteSession(id: id)
            sessions = DatabaseManager.shared.fetchSessions()
        }
    }
}
