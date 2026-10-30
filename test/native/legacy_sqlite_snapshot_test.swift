import Foundation
import SQLite3

enum CheckFailure: Error { case assertion(String) }
func check(_ value: @autoclosure () throws -> Bool, _ message: String) throws {
  if try !value() { throw CheckFailure.assertion(message) }
}
func execute(_ db: OpaquePointer, _ sql: String) throws {
  let status = sqlite3_exec(db, sql, nil, nil, nil)
  try check(status == SQLITE_OK,
            "Fixture SQL failed (\(status)): \(String(cString: sqlite3_errmsg(db)))")
}
func row(_ db: OpaquePointer, _ query: String) throws -> [String] {
  var statement: OpaquePointer?
  let status = sqlite3_prepare_v2(db, query, -1, &statement, nil)
  try check(status == SQLITE_OK,
            "Query failed (\(status)): \(String(cString: sqlite3_errmsg(db)))")
  guard let statement else { throw CheckFailure.assertion("No query statement") }
  defer { sqlite3_finalize(statement) }
  try check(sqlite3_step(statement) == SQLITE_ROW, "Missing exported row")
  return (0..<sqlite3_column_count(statement)).map {
    guard let text = sqlite3_column_text(statement, $0) else { return "" }
    return String(cString: text)
  }
}

@main
struct LegacySnapshotChecks {
  static func main() async throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("compositesai-legacy-test-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let original = root.appendingPathComponent("UserDataModel.sqlite")
    var db: OpaquePointer?
    try check(sqlite3_open(original.path, &db) == SQLITE_OK, "Fixture open failed")
    guard let db else { throw CheckFailure.assertion("No fixture database") }
    defer { sqlite3_close(db) }
    try execute(db, "PRAGMA journal_mode=WAL; PRAGMA wal_autocheckpoint=0;")
    for table in ["ZUSERCOREMATERIAL", "ZUSERFIBERMATERIAL", "ZUSERLAMINAMATERIAL", "ZUSERMATRIXMATERIAL"] {
      try execute(db, "CREATE TABLE \(table)(ZNAME TEXT, ZTYPE TEXT, ZPROPERTIES BLOB)")
      // Opaque legacy properties must survive exactly, even when no new-library
      // material type or trustworthy unit conversion exists.
      try execute(db, "INSERT INTO \(table) VALUES('材料 α '' original','Anisotropic',X'00010203FFFE80')")
    }
    try execute(db, "CREATE TABLE ZUSERSTACKINGSEQUENCE(ZNAME TEXT, ZSTACKINGSEQUENCE TEXT)")
    try execute(db, "INSERT INTO ZUSERSTACKINGSEQUENCE VALUES('旧铺层','[0/45/-45/90]s')")
    try execute(db, "CREATE TABLE Z_METADATA(Z_VERSION INTEGER, Z_PLIST BLOB)")
    try execute(db, "INSERT INTO Z_METADATA VALUES(1,X'62706C6973743030')")
    try execute(db, "PRAGMA user_version=73; PRAGMA application_id=1396922192")
    try execute(db, "CREATE TABLE ZOPAQUEVALUES(ZINTEGER INTEGER,ZREAL REAL,ZNULL BLOB,ZTEXT TEXT,ZBLOB BLOB,ZUNITS TEXT)")
    try execute(db, "INSERT INTO ZOPAQUEVALUES VALUES(-9223372036854775808,-1.25,NULL,CAST(X'610062F09F8C8D' AS TEXT),X'00FF80','legacy units: unknown')")
    let wal = URL(fileURLWithPath: original.path + "-wal")
    let originalBytes = try Data(contentsOf: original)
    let originalWAL = try Data(contentsOf: wal)
    let bytes = try await LegacySQLiteSnapshot.createInBackground(from: original)
    try check(try Data(contentsOf: original) == originalBytes, "Source database changed")
    try check(try Data(contentsOf: wal) == originalWAL, "Source WAL changed")
    let exported = root.appendingPathComponent("Export.sqlite")
    try await LegacySQLiteSnapshot.writeInBackground(bytes, to: exported)
    var snapshot: OpaquePointer?
    try check(sqlite3_open_v2(exported.path, &snapshot, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              "Snapshot open failed")
    guard let snapshot else { throw CheckFailure.assertion("No exported database") }
    defer { sqlite3_close(snapshot) }
    try check(sqlite3_db_readonly(snapshot, "main") == 1, "Snapshot was not opened read-only")
    try check(try row(snapshot, "PRAGMA journal_mode") == ["delete"],
              "Export still requires WAL sidecars")
    try check(try row(snapshot, "PRAGMA user_version") == ["73"], "User version changed")
    try check(try row(snapshot, "PRAGMA application_id") == ["1396922192"], "Application ID changed")
    for table in ["ZUSERCOREMATERIAL", "ZUSERFIBERMATERIAL", "ZUSERLAMINAMATERIAL", "ZUSERMATRIXMATERIAL"] {
      let values = try row(snapshot, "SELECT ZNAME,ZTYPE,hex(ZPROPERTIES) FROM \(table)")
      try check(values == ["材料 α ' original", "Anisotropic", "00010203FFFE80"], "Legacy values altered")
    }
    try check(try row(snapshot, "SELECT ZNAME,ZSTACKINGSEQUENCE FROM ZUSERSTACKINGSEQUENCE")
              == ["旧铺层", "[0/45/-45/90]s"], "Layup changed")
    try check(try row(snapshot, "SELECT hex(Z_PLIST) FROM Z_METADATA") == ["62706C6973743030"],
              "Core Data metadata lost")
    try check(try row(snapshot, "SELECT typeof(ZINTEGER),ZINTEGER,typeof(ZREAL),ZREAL,typeof(ZNULL),typeof(ZTEXT),hex(ZTEXT),typeof(ZBLOB),hex(ZBLOB),ZUNITS FROM ZOPAQUEVALUES")
              == ["integer", "-9223372036854775808", "real", "-1.25", "null", "text",
                  "610062F09F8C8D", "blob", "00FF80", "legacy units: unknown"],
              "Opaque SQLite values, embedded NUL text or unknown units changed")
    for suffix in ["-wal", "-shm", "-journal"] {
      try check(!FileManager.default.fileExists(atPath: exported.path + suffix),
                "Standalone export created a sidecar")
    }

    // Existing transaction files belong to the selected destination, not this
    // snapshot. Reject replacement without changing either database or sidecar.
    let protected = root.appendingPathComponent("ProtectedExport.sqlite")
    let previous = Data("existing destination bytes".utf8)
    try previous.write(to: protected)
    for suffix in ["-wal", "-shm", "-journal"] {
      let companion = URL(fileURLWithPath: protected.path + suffix)
      let pending = Data("untouched destination \(suffix)".utf8)
      try pending.write(to: companion)
      do {
        try await LegacySQLiteSnapshot.writeInBackground(bytes, to: protected)
        throw CheckFailure.assertion("Destination companion was ignored")
      } catch is LegacySQLiteSnapshot.Failure { }
      try check(try Data(contentsOf: protected) == previous, "Existing destination changed")
      try check(try Data(contentsOf: companion) == pending, "Destination companion changed")
      try check(try Data(contentsOf: original) == originalBytes, "Source changed on rejected write")
      try check(try Data(contentsOf: wal) == originalWAL, "Source WAL changed on rejected write")
      try FileManager.default.removeItem(at: companion)
    }

    // Orphaned and dangling companions are also unsafe, even without a main DB.
    let orphan = root.appendingPathComponent("OrphanedExport.sqlite")
    let orphanWAL = URL(fileURLWithPath: orphan.path + "-wal")
    let orphanBytes = Data("orphaned transaction bytes".utf8)
    try orphanBytes.write(to: orphanWAL)
    do {
      try await LegacySQLiteSnapshot.writeInBackground(bytes, to: orphan)
      throw CheckFailure.assertion("Orphaned WAL was ignored")
    } catch is LegacySQLiteSnapshot.Failure { }
    try check(!FileManager.default.fileExists(atPath: orphan.path), "Rejected output was created")
    try check(try Data(contentsOf: orphanWAL) == orphanBytes, "Orphaned WAL changed")
    try FileManager.default.removeItem(at: orphanWAL)
    let missingTarget = root.appendingPathComponent("MissingCompanionTarget")
    try FileManager.default.createSymbolicLink(at: orphanWAL, withDestinationURL: missingTarget)
    do {
      try await LegacySQLiteSnapshot.writeInBackground(bytes, to: orphan)
      throw CheckFailure.assertion("Dangling WAL symlink was ignored")
    } catch is LegacySQLiteSnapshot.Failure { }
    try check(!FileManager.default.fileExists(atPath: orphan.path), "Symlink rejection created output")
    try check(try FileManager.default.destinationOfSymbolicLink(atPath: orphanWAL.path)
                == missingTarget.path, "Dangling companion changed")

    let fresh = root.appendingPathComponent("FreshAfterRejection.sqlite")
    try await LegacySQLiteSnapshot.writeInBackground(bytes, to: fresh)
    try check(try Data(contentsOf: fresh) == bytes, "Fresh export after rejection failed")

    // A valid SQLite header does not make a damaged table safe to export.
    let pageSize = Int(try row(snapshot, "PRAGMA page_size")[0])!
    let rootPage = Int(try row(snapshot,
      "SELECT rootpage FROM sqlite_master WHERE name='ZUSERSTACKINGSEQUENCE'")[0])!
    var damagedBytes = bytes
    damagedBytes[(rootPage - 1) * pageSize] = 0xFF
    let damaged = root.appendingPathComponent("DamagedPage.sqlite")
    try damagedBytes.write(to: damaged)
    do {
      _ = try LegacySQLiteSnapshot.create(from: damaged)
      throw CheckFailure.assertion("Damaged table was accepted")
    } catch is LegacySQLiteSnapshot.Failure { }
    try check(try Data(contentsOf: damaged) == damagedBytes, "Damaged source was changed")
    let corrupt = root.appendingPathComponent("Corrupt.sqlite")
    let invalid = Data("not a SQLite database".utf8)
    try invalid.write(to: corrupt)
    do {
      _ = try LegacySQLiteSnapshot.create(from: corrupt)
      throw CheckFailure.assertion("Corrupt database was accepted")
    } catch is LegacySQLiteSnapshot.Failure { }
    try check(try Data(contentsOf: corrupt) == invalid, "Corrupt source was changed")
    let missing = root.appendingPathComponent("Missing.sqlite")
    do {
      _ = try LegacySQLiteSnapshot.create(from: missing)
      throw CheckFailure.assertion("Missing database was accepted")
    } catch is LegacySQLiteSnapshot.Failure { }
    try check(!FileManager.default.fileExists(atPath: missing.path), "Missing source was created")
    print("Native legacy snapshot checks passed: read-only standalone export, WAL consistency, destination companion protection, fresh export recovery, all material kinds, layups, SQLite value types, unknown units, metadata, damaged/corrupt and missing stores.")
  }
}
