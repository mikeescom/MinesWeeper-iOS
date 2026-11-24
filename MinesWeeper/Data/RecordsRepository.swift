//
//  RecordsRepository.swift
//  MinesWeeper
//

import Foundation
import FirebaseDatabase

/// Saves finished games to the Realtime Database under the signed-in user's Firebase uid.
/// Offline persistence (enabled in AppDelegate) queues writes made without a connection.
final class RecordsRepository {

    static let shared = RecordsRepository()

    private static let usersTable = "users"

    private lazy var usersReference = Database.database().reference(withPath: Self.usersTable)

    private init() {}

    func addRecord(_ record: RecordItem, userId: String) {
        usersReference.child(userId).childByAutoId().setValue(record.dictionary) { error, reference in
            if let error {
                print("RecordsRepository: saving record failed: \(error)")
            } else {
                print("RecordsRepository: saved record \(reference.key ?? "?")")
            }
        }
    }
}
