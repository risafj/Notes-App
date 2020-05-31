import Foundation
import SQLite3

struct Note {
    var id: Int32
    var content: String
}

class NoteManager {
    var database: OpaquePointer?

    // "static" enables you to use the singleton pattern and use class methods without instantiating it.
    // e.g. by calling "NoteManager.shared.connect()"
    static let shared = NoteManager()

    // Making the init method private so it's not callable from outside.
    private init() {
    }
    
    func connect() {
        // Do nothing if there is already a DB connection.
        if database != nil {
            return
        }

        // Try to get a path for creating a DB file.
        let databaseURL = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("notes.sqlite")

        // &database is a pointer, and we're saying we'll store the connection to the DB in this location.
        if sqlite3_open(databaseURL.path, &database) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        if sqlite3_exec(
            database,
            // sqlite will also automatically create rowid (int)).
            """
            CREATE TABLE IF NOT EXISTS notes (
                content TEXT
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
    }
    
    func create() -> Int {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO notes (content) VALUES ('Write a note!')",
            -1,
            &statement,
            nil
        ) != SQLITE_OK {
            print("Error creating note insert statement")
            return -1
        }

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error inserting note")
            return -1
        }

        // Call this for any cleanup behind the scenes.
        sqlite3_finalize(statement)
        // Returning the rowid that we just created.
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    func getNotes() -> [Note] {
        connect()

        var result: [Note] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "SELECT rowid, content FROM notes", -1, &statement, nil) != SQLITE_OK {
            print("Error creating select statement")
            return []
        }

        // Run the query for each row.
        while sqlite3_step(statement) == SQLITE_ROW {
            result.append(Note(
                // rowid is our first column (index 0 in zero-indexed list)
                id: sqlite3_column_int(statement, 0),
                // The note content is our second column (index 1)
                content: String(cString: sqlite3_column_text(statement, 1))
            ))
        }

        sqlite3_finalize(statement)
        return result
    }
    
    func saveNote(note: Note) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE notes SET content = ? WHERE rowid = ?",
            -1,
            &statement,
            nil
        ) != SQLITE_OK {
            print("Error creating note update statement")
        }
        // This list is one-index, not zero.
        sqlite3_bind_text(statement, 1, NSString(string: note.content).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, note.id)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("Error saving note")
        }
        sqlite3_finalize(statement)
    }
}
