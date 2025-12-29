import Foundation
import SQLite3

class iMessageDatabaseReader {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        // Default iMessage database path
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = "\(homeDir)/Library/Messages/chat.db"
    }
    
    init(customPath: String) {
        self.dbPath = customPath
    }
    
    static func checkFullDiskAccess() -> Bool {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let dbPath = "\(homeDir)/Library/Messages/chat.db"
        return FileManager.default.isReadableFile(atPath: dbPath)
    }
    
    func open() throws {
        guard FileManager.default.fileExists(atPath: dbPath) else {
            throw DatabaseError.fileNotFound
        }
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            throw DatabaseError.cannotOpen(String(cString: sqlite3_errmsg(db)))
        }
    }
    
    func close() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    func getMessages(fromDaysAgo days: Int) throws -> [Message] {
        guard db != nil else { throw DatabaseError.notConnected }
        
        // Calculate date threshold (Apple's Core Data epoch is Jan 1, 2001)
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        let appleEpochThreshold = threshold.timeIntervalSince(Date(timeIntervalSinceReferenceDate: 0)) * 1_000_000_000
        
        let query = """
            SELECT 
                m.ROWID,
                m.text,
                m.is_from_me,
                m.date,
                m.cache_has_attachments,
                h.id as handle_id,
                c.display_name as chat_name,
                c.chat_identifier
            FROM message m
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            LEFT JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
            LEFT JOIN chat c ON cmj.chat_id = c.ROWID
            WHERE m.date > ?
            ORDER BY m.date DESC
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_int64(statement, 1, Int64(appleEpochThreshold))
        
        var messages: [Message] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let rowId = sqlite3_column_int64(statement, 0)
            let text = sqlite3_column_text(statement, 1).map { String(cString: $0) }
            let isFromMe = sqlite3_column_int(statement, 2) == 1
            let dateNano = sqlite3_column_int64(statement, 3)
            let hasAttachments = sqlite3_column_int(statement, 4) == 1
            let handleId = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let chatName = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            let chatIdentifier = sqlite3_column_text(statement, 7).map { String(cString: $0) }
            
            // Convert Apple's nanoseconds to Date
            let date = Date(timeIntervalSinceReferenceDate: TimeInterval(dateNano) / 1_000_000_000)
            
            let message = Message(
                id: rowId,
                text: text,
                isFromMe: isFromMe,
                date: date,
                hasAttachments: hasAttachments,
                handleId: handleId,
                chatName: chatName,
                chatIdentifier: chatIdentifier
            )
            messages.append(message)
        }
        
        return messages
    }
    
    func getContactName(for handleId: String) throws -> String? {
        guard db != nil else { throw DatabaseError.notConnected }
        
        let query = """
            SELECT id FROM handle WHERE id = ?
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, handleId, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return sqlite3_column_text(statement, 0).map { String(cString: $0) }
        }
        
        return nil
    }
}

struct Message: Identifiable {
    let id: Int64
    let text: String?
    let isFromMe: Bool
    let date: Date
    let hasAttachments: Bool
    let handleId: String?
    let chatName: String?
    let chatIdentifier: String?
    
    var contactIdentifier: String {
        chatName ?? handleId ?? chatIdentifier ?? "Unknown"
    }
    
    var displayName: String {
        let identifier = contactIdentifier
        // Format phone numbers nicely
        if identifier.hasPrefix("+") || identifier.allSatisfy({ $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " }) {
            return formatPhoneNumber(identifier)
        }
        return identifier
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        if digits.count == 10 {
            let areaCode = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "(\(areaCode)) \(middle)-\(last)"
        } else if digits.count == 11 && digits.first == "1" {
            let remaining = digits.dropFirst()
            let areaCode = remaining.prefix(3)
            let middle = remaining.dropFirst(3).prefix(3)
            let last = remaining.suffix(4)
            return "+1 (\(areaCode)) \(middle)-\(last)"
        }
        return phone
    }
}

enum DatabaseError: Error, LocalizedError {
    case fileNotFound
    case cannotOpen(String)
    case notConnected
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "iMessage database not found. Make sure you have Full Disk Access enabled."
        case .cannotOpen(let message):
            return "Cannot open database: \(message)"
        case .notConnected:
            return "Database not connected"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        }
    }
}
