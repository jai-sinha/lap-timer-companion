//
//  DatabaseManager.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createSessionsTable()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("LapTimerCompanion.sqlite")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            print("Successfully opened connection to database at \(fileURL.path)")
        } else {
            print("Unable to open database")
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            print("Database connection closed")
        } else {
            print("Unable to close database")
        }
    }
    
    private func createSessionsTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date REAL NOT NULL,
                stats TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                lap_count INTEGER,
                best_lap_time REAL,
                total_time REAL
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) == SQLITE_OK {
            print("Sessions table created successfully")
        } else {
            print("Unable to create sessions table")
        }
    }
    
    func insertSession(date: Date,
                      stats: String,
                      latitude: Double? = nil,
                      longitude: Double? = nil,
                      lapCount: Int? = nil,
                      bestLapTime: Double? = nil,
                      totalTime: Double? = nil) {
        let insertSQL = """
            INSERT INTO sessions (date, stats, latitude, longitude, 
                                lap_count, best_lap_time, total_time) 
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 2, stats, -1, nil)
            
            if let lat = latitude {
                sqlite3_bind_double(statement, 3, lat)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            if let lon = longitude {
                sqlite3_bind_double(statement, 4, lon)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            if let laps = lapCount {
                sqlite3_bind_int(statement, 5, Int32(laps))
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            if let bestLap = bestLapTime {
                sqlite3_bind_double(statement, 6, bestLap)
            } else {
                sqlite3_bind_null(statement, 6)
            }
            
            if let total = totalTime {
                sqlite3_bind_double(statement, 7, total)
            } else {
                sqlite3_bind_null(statement, 7)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Session inserted successfully")
            } else {
                print("Could not insert session")
            }
        } else {
            print("INSERT statement could not be prepared")
        }
        
        sqlite3_finalize(statement)
    }
    
    func fetchSessions() -> [Session] {
        let querySQL = "SELECT * FROM sessions ORDER BY date DESC;"
        var statement: OpaquePointer?
        var sessions: [Session] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let dateInterval = sqlite3_column_double(statement, 1)
                let date = Date(timeIntervalSince1970: dateInterval)
                
                let stats = String(cString: sqlite3_column_text(statement, 2))
                
                let lat = sqlite3_column_type(statement, 3) != SQLITE_NULL ?
                    sqlite3_column_double(statement, 3) : nil
                let lon = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
                    sqlite3_column_double(statement, 4) : nil
                let lapCount = sqlite3_column_type(statement, 5) != SQLITE_NULL ?
                    Int(sqlite3_column_int(statement, 5)) : nil
                let bestLapTime = sqlite3_column_type(statement, 6) != SQLITE_NULL ?
                    sqlite3_column_double(statement, 6) : nil
                let totalTime = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
                    sqlite3_column_double(statement, 7) : nil
                
                let session = Session(id: id,
                                    date: date,
                                    stats: stats,
                                    latitude: lat,
                                    longitude: lon,
                                    lapCount: lapCount,
                                    bestLapTime: bestLapTime,
                                    totalTime: totalTime)
                sessions.append(session)
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        
        sqlite3_finalize(statement)
        return sessions
    }
    
    func deleteSession(id: Int64) {
        let deleteSQL = "DELETE FROM sessions WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Session deleted successfully")
            } else {
                print("Could not delete session")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        
        sqlite3_finalize(statement)
    }
}
