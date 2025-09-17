//
//  DatabaseManager.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/16/25.
//

import Foundation
import SQLite3
import ConnectIQ

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createSessionsTable()
        createDevicesTable()
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
    
    private func createDevicesTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS devices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                uuid TEXT UNIQUE NOT NULL,
                display_name TEXT NOT NULL,
                friendly_name TEXT,
                device_type INTEGER,
                last_updated REAL NOT NULL
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) == SQLITE_OK {
            print("Devices table created successfully")
        } else {
            print("Unable to create devices table")
        }
    }
    
    // MARK: - Session Methods
    
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
    
    // MARK: - Device Storage Methods
    
    func clearAllDevices() {
        let deleteSQL = "DELETE FROM devices;"
        if sqlite3_exec(db, deleteSQL, nil, nil, nil) == SQLITE_OK {
            print("All devices cleared from database")
        } else {
            print("Failed to clear devices from database")
        }
    }
    
    func saveDevices(_ devices: [String: IQDevice]) {
        // Clear existing devices first as per documentation
        clearAllDevices()
        
        for (uuidString, device) in devices {
            insertDeviceUUID(uuidString, device: device)
        }
    }
    
    private func insertDeviceUUID(_ uuidString: String, device: IQDevice) {
        let insertSQL = """
            INSERT OR REPLACE INTO devices (uuid, display_name, friendly_name, device_type, last_updated) 
            VALUES (?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, "Garmin Device", -1, nil)  // Generic name since we can't access properties
            sqlite3_bind_null(statement, 3)  // No friendly name
            sqlite3_bind_int(statement, 4, 0)  // Default device type
            sqlite3_bind_double(statement, 5, Date().timeIntervalSince1970)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Device saved successfully: \(uuidString)")
            } else {
                print("Could not save device")
            }
        } else {
            print("INSERT device statement could not be prepared")
        }
        
        sqlite3_finalize(statement)
    }
    
    func hasStoredDevices() -> Bool {
        let querySQL = "SELECT COUNT(*) FROM devices;"
        var statement: OpaquePointer?
        var hasDevices = false
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                hasDevices = count > 0
            }
        }
        
        sqlite3_finalize(statement)
        return hasDevices
    }
    
    func fetchStoredDevices() -> [String: IQDevice] {
        // Since IQDevice objects cannot be directly reconstructed from stored data,
        // we return an empty dictionary but log the stored device UUIDs for reference
        let querySQL = "SELECT uuid, display_name FROM devices ORDER BY last_updated DESC;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let uuidCString = sqlite3_column_text(statement, 0) else {
                    continue
                }
                let uuidString = String(cString: uuidCString)
                
                guard let displayNameCString = sqlite3_column_text(statement, 1) else {
                    continue
                }
                let displayName = String(cString: displayNameCString)
                
                print("Found stored device: \(displayName) (\(uuidString))")
            }
        }
        
        sqlite3_finalize(statement)
        
        // Return empty dictionary since IQDevice objects cannot be reconstructed
        // The app should use this method to check if devices were previously stored
        // and then trigger device discovery through ConnectIQ SDK if needed
        return [:]
    }
}
