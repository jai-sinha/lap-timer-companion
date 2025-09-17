//
//  Session.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import Foundation

struct Session: Identifiable, Codable {
    let id: Int64?
    let date: Date
    let stats: String
    let latitude: Double?
    let longitude: Double?
    let lapCount: Int?
    let bestLapTime: Double?
    let totalTime: Double?
    
    init(id: Int64? = nil,
         date: Date,
         stats: String,
         latitude: Double? = nil,
         longitude: Double? = nil,
         lapCount: Int? = nil,
         bestLapTime: Double? = nil,
         totalTime: Double? = nil) {
        self.id = id
        self.date = date
        self.stats = stats
        self.latitude = latitude
        self.longitude = longitude
        self.lapCount = lapCount
        self.bestLapTime = bestLapTime
        self.totalTime = totalTime
    }
}
