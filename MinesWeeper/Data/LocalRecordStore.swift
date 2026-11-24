//
//  LocalRecordStore.swift
//  MinesWeeper
//
//  The on-device copy of the player's records, like the Room database on Android. Records are
//  keyed by their Realtime Database key and kept in a JSON file in Application Support.
//

import Foundation

final class LocalRecordStore {

    static let shared = LocalRecordStore(fileURL: LocalRecordStore.defaultFileURL)

    private static var defaultFileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("records.json")
    }

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.msmikeescom.MinesWeeper.LocalRecordStore")
    private var cache: [String: RecordItem]?

    /// [fileURL] is injectable so tests can use a temporary file.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// All stored records, newest first.
    func allRecords() -> [RecordItem] {
        queue.sync { load().values.sorted { $0.timeStamp > $1.timeStamp } }
    }

    func allIds() -> Set<String> {
        queue.sync { Set(load().keys) }
    }

    /// Stores [record] under [id] unless a record with that id is already stored.
    /// Returns whether it was added.
    @discardableResult
    func insert(_ record: RecordItem, id: String) -> Bool {
        queue.sync { () -> Bool in
            var records = load()
            guard records[id] == nil else { return false }
            records[id] = record
            save(records)
            return true
        }
    }

    func deleteAll() {
        queue.sync {
            cache = [:]
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Must be called on `queue`

    private func load() -> [String: RecordItem] {
        if let cache { return cache }
        var records: [String: RecordItem] = [:]
        if let data = try? Data(contentsOf: fileURL) {
            do {
                records = try JSONDecoder().decode([String: RecordItem].self, from: data)
            } catch {
                print("LocalRecordStore: discarding unreadable records file: \(error)")
            }
        }
        cache = records
        return records
    }

    private func save(_ records: [String: RecordItem]) {
        cache = records
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(records).write(to: fileURL, options: .atomic)
        } catch {
            print("LocalRecordStore: saving records failed: \(error)")
        }
    }
}
