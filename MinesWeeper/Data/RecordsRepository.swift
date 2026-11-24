//
//  RecordsRepository.swift
//  MinesWeeper
//

import Foundation
import FirebaseDatabase

/// Saves finished games to the Realtime Database under the signed-in user's Firebase uid and
/// keeps the on-device copy in step, like MainRepository plus the child listener on Android.
/// Offline persistence (enabled in AppDelegate) queues writes made without a connection.
final class RecordsRepository {

    static let shared = RecordsRepository(localStore: .shared)

    private static let usersTable = "users"

    private lazy var usersReference = Database.database().reference(withPath: Self.usersTable)
    private let localStore: LocalRecordStore

    /// The node and observer handle of the running sync, if any.
    private var syncedReference: DatabaseReference?
    private var syncHandle: DatabaseHandle?

    init(localStore: LocalRecordStore) {
        self.localStore = localStore
    }

    /// Copies the user's server records into the local store, now and as new ones arrive.
    /// Calling it again for the same user does nothing.
    func startSync(userId: String) {
        let reference = usersReference.child(userId)
        if syncedReference?.url == reference.url { return }
        stopSync()
        syncedReference = reference
        syncHandle = reference.observe(.childAdded, with: { [localStore] snapshot in
            guard let dictionary = snapshot.value as? [String: Any],
                  let record = RecordItem(dictionary: dictionary) else {
                print("RecordsRepository: skipping malformed record \(snapshot.key)")
                return
            }
            localStore.insert(record, id: snapshot.key)
        }, withCancel: { error in
            print("RecordsRepository: sync cancelled: \(error)")
        })
    }

    func stopSync() {
        if let syncedReference, let syncHandle {
            syncedReference.removeObserver(withHandle: syncHandle)
        }
        syncedReference = nil
        syncHandle = nil
    }

    /// Saves [record] locally and to the server under a new unique key.
    func addRecord(_ record: RecordItem, userId: String) {
        let reference = usersReference.child(userId).childByAutoId()
        if let key = reference.key {
            localStore.insert(record, id: key)
        }
        reference.setValue(record.dictionary) { error, reference in
            if let error {
                print("RecordsRepository: saving record failed: \(error)")
            } else {
                print("RecordsRepository: saved record \(reference.key ?? "?")")
            }
        }
    }

    /// The records stored on this device, newest first.
    func loadAllRecords() -> [RecordItem] {
        localStore.allRecords()
    }

    /// Stops syncing and forgets the records stored on this device.
    func clearLocalRecords() {
        stopSync()
        localStore.deleteAll()
    }
}
