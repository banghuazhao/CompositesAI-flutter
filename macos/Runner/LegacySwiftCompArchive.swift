import Foundation
import SQLite3

/// A consistent snapshot retains every Core Data field without interpreting
/// legacy material types or units. The source connection is read-only.
enum LegacySQLiteSnapshot {
  enum Failure: Error { case unreadable, tooLarge }

  static func create(from source: URL) throws -> Data {
    let deadline = ProcessInfo.processInfo.systemUptime + 10
    var sourceDB: OpaquePointer?
    guard sqlite3_open_v2(source.path, &sourceDB,
                         SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK,
          let sourceDB else {
      if let sourceDB { sqlite3_close(sourceDB) }
      throw Failure.unreadable
    }
    defer { sqlite3_close(sourceDB) }
    sqlite3_busy_timeout(sourceDB, 2000)

    var sizeStatement: OpaquePointer?
    guard sqlite3_prepare_v2(sourceDB, "PRAGMA page_size", -1, &sizeStatement, nil) == SQLITE_OK,
          let sizeStatement else { throw Failure.unreadable }
    let sizeStatus = sqlite3_step(sizeStatement)
    let pageSize = sqlite3_column_int(sizeStatement, 0)
    sqlite3_finalize(sizeStatement)
    guard sizeStatus == SQLITE_ROW, pageSize >= 512, pageSize <= 65536 else {
      throw Failure.unreadable
    }

    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent("SwiftComp-\(UUID().uuidString).sqlite")
    defer {
      for suffix in ["", "-wal", "-shm", "-journal"] {
        try? FileManager.default.removeItem(atPath: temporary.path + suffix)
      }
    }
    var destinationDB: OpaquePointer?
    guard sqlite3_open_v2(temporary.path, &destinationDB,
                         SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK,
          let destinationDB else {
      if let destinationDB { sqlite3_close(destinationDB) }
      throw Failure.unreadable
    }
    var closed = false
    defer { if !closed { sqlite3_close(destinationDB) } }
    guard let backup = sqlite3_backup_init(destinationDB, "main", sourceDB, "main") else {
      throw Failure.unreadable
    }
    var status: Int32 = SQLITE_OK
    repeat {
      let remaining = deadline - ProcessInfo.processInfo.systemUptime
      if remaining <= 0 { break }
      sqlite3_busy_timeout(sourceDB, Int32(min(2000, remaining * 1000)))
      status = sqlite3_backup_step(backup, 128)
      if status == SQLITE_BUSY || status == SQLITE_LOCKED {
        let delay = min(0.05, deadline - ProcessInfo.processInfo.systemUptime)
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
      }
      if Int64(sqlite3_backup_pagecount(backup)) * Int64(pageSize) > 64 * 1024 * 1024 {
        sqlite3_backup_finish(backup)
        throw Failure.tooLarge
      }
    } while (status == SQLITE_OK || status == SQLITE_BUSY || status == SQLITE_LOCKED)
      && ProcessInfo.processInfo.systemUptime < deadline
    let finished = sqlite3_backup_finish(backup)
    guard status == SQLITE_DONE, finished == SQLITE_OK else { throw Failure.unreadable }

    // A WAL source leaves its journal mode in the backup's header. Export one
    // standalone database that can be reopened read-only without WAL/SHM files.
    guard try singleTextResult(in: destinationDB, sql: "PRAGMA journal_mode=DELETE") == "delete"
    else { throw Failure.unreadable }
    try validate(destinationDB, until: deadline)
    guard sqlite3_close(destinationDB) == SQLITE_OK else { throw Failure.unreadable }
    closed = true
    let size = try temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    guard size <= 64 * 1024 * 1024 else { throw Failure.tooLarge }
    let data = try Data(contentsOf: temporary)
    guard ProcessInfo.processInfo.systemUptime < deadline else { throw Failure.unreadable }
    return data
  }

  private static func singleTextResult(in db: OpaquePointer, sql: String) throws -> String {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
          let statement else { throw Failure.unreadable }
    defer { sqlite3_finalize(statement) }
    guard sqlite3_step(statement) == SQLITE_ROW,
          let text = sqlite3_column_text(statement, 0) else { throw Failure.unreadable }
    let value = String(cString: text)
    guard sqlite3_step(statement) == SQLITE_DONE else { throw Failure.unreadable }
    return value
  }

  private static func validate(_ db: OpaquePointer, until deadline: TimeInterval) throws {
    // Keep the deadline pointer alive for every synchronous SQLite callback.
    try withUnsafePointer(to: deadline) { pointer in
      sqlite3_progress_handler(db, 1000, { context in
        guard let context else { return 1 }
        let deadline = context.assumingMemoryBound(to: TimeInterval.self).pointee
        return ProcessInfo.processInfo.systemUptime >= deadline ? 1 : 0
      }, UnsafeMutableRawPointer(mutating: pointer))
      defer { sqlite3_progress_handler(db, 0, nil, nil) }
      guard ProcessInfo.processInfo.systemUptime < deadline,
            try singleTextResult(in: db, sql: "PRAGMA quick_check") == "ok",
            ProcessInfo.processInfo.systemUptime < deadline else { throw Failure.unreadable }
    }
  }

  static func createInBackground(from source: URL) async throws -> Data {
    // SQLite's synchronous C API stays on one worker; no database handles or
    // Flutter callbacks cross the queue boundary.
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(with: Result { try create(from: source) })
      }
    }
  }

  static func writeInBackground(_ data: Data, to destination: URL) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(with: Result {
          // Never pair a replacement main database with another database's
          // pending transactions, and never delete companions owned elsewhere.
          let files = FileManager.default
          for suffix in ["-wal", "-shm", "-journal"] {
            let companion = destination.path + suffix
            guard !files.fileExists(atPath: companion),
                  (try? files.destinationOfSymbolicLink(atPath: companion)) == nil else {
              throw Failure.unreadable
            }
          }
          try data.write(to: destination, options: .atomic)
        })
      }
    }
  }
}

#if canImport(FlutterMacOS)
import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

@MainActor
enum LegacySwiftCompArchive {
  private static var exporting = false

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "compositesai/legacy-swiftcomp", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      // Flutter's default platform channel invokes handlers on the main thread.
      MainActor.assumeIsolated {
        switch call.method {
        case "hasLegacyData": result(legacyStore() != nil)
        case "exportLegacyData": export(result: result)
        default: result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private static func legacyStore() -> URL? {
    guard let support = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
    let candidates = [support, support.appendingPathComponent("SwiftComp"),
                      support.appendingPathComponent("maccatalyst.com.cdmHUB.SwiftComp")]
    return candidates.map { $0.appendingPathComponent("UserDataModel.sqlite") }.first { url in
      guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      else { return false }
      return values.isRegularFile == true && values.isSymbolicLink != true
    }
  }

  private static func export(result: @escaping FlutterResult) {
    guard !exporting else {
      result(FlutterError(code: "busy", message: "An export is already open.", details: nil))
      return
    }
    guard let source = legacyStore() else {
      result(FlutterError(code: "not_found", message: "No legacy data was found.", details: nil))
      return
    }
    exporting = true
    // This task bridges Flutter's callback to an AppKit async save panel. Every
    // branch completes the Flutter result once, and releases the busy state.
    Task { @MainActor in
      defer { exporting = false }
      do {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "SwiftComp-Legacy-Data.sqlite"
        panel.allowedContentTypes = [UTType(filenameExtension: "sqlite") ?? .database]
        panel.canCreateDirectories = true
        guard await panel.begin() == .OK, let destination = panel.url else {
          result(false)
          return
        }
        let resolvedDestination = destination.resolvingSymlinksInPath().standardizedFileURL
        let sourceFiles = ["", "-wal", "-shm", "-journal"].map {
          URL(fileURLWithPath: source.path + $0).resolvingSymlinksInPath().standardizedFileURL
        }
        guard !sourceFiles.contains(resolvedDestination) else {
          throw LegacySQLiteSnapshot.Failure.unreadable
        }
        let access = destination.startAccessingSecurityScopedResource()
        defer { if access { destination.stopAccessingSecurityScopedResource() } }
        let data = try await LegacySQLiteSnapshot.createInBackground(from: source)
        try await LegacySQLiteSnapshot.writeInBackground(data, to: destination)
        result(true)
      } catch {
        // Do not log material names, properties, or local user paths.
        result(FlutterError(code: "export_failed", message: "Could not export legacy data.", details: nil))
      }
    }
  }
}
#endif
