import SwiftUI

class AppMessageViewModel: ObservableObject {
    @Published var tableEntries: [TableEntry]
    @Published var logMessages: [String]
    
    init(tableEntries: [TableEntry] = [], logMessages: [String] = []) {
        self.tableEntries = tableEntries
        self.logMessages = logMessages
    }
    
    func addLog(_ message: String) {
        logMessages.append(message)
        while logMessages.count > kMaxLogMessages {
            logMessages.removeFirst()
        }
    }
}
