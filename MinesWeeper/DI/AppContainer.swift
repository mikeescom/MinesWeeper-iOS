//
//  AppContainer.swift
//  MinesWeeper
//
//  The app's dependencies, built once at launch and handed to each screen through its
//  initializer. This plays the role Hilt's SingletonComponent plays on Android: screens depend
//  on protocols, and only this file knows the concrete Firebase and on-disk implementations.
//

import UIKit

final class AppContainer {
    let auth: AuthProviding
    let records: RecordsStoring
    let settings: GameSettings

    init(auth: AuthProviding, records: RecordsStoring, settings: GameSettings) {
        self.auth = auth
        self.records = records
        self.settings = settings
    }

    /// The real dependencies. Call after FirebaseApp.configure().
    static func live() -> AppContainer {
        AppContainer(
            auth: FirebaseAuthService(),
            records: RecordsRepository(localStore: LocalRecordStore(fileURL: LocalRecordStore.defaultFileURL)),
            settings: UserDefaultsSettings())
    }

    /// Signs out and forgets this player's preferences and local records, as Android's logout does.
    func logOut() {
        auth.signOut()
        settings.clear()
        records.clearLocalRecords()
    }

    /// Deletes the player's account and everything stored for it, as App Store guideline
    /// 5.1.1(v) requires: confirms their identity again, deletes their records on the server,
    /// deletes the Firebase account, then clears this device. Fails with CancellationError if
    /// they cancel a sign-in sheet. [password] is used for email accounts.
    func deleteAccount(presenting viewController: UIViewController, password: String?,
                       completion: @escaping (Error?) -> Void) {
        guard let userId = auth.currentUserId else {
            completion(FirebaseAuthService.AuthServiceError.notSignedIn)
            return
        }
        auth.reauthenticate(presenting: viewController, password: password) { [self] error in
            if let error { return completion(error) }
            records.deleteServerRecords(userId: userId) { [self] error in
                if let error { return completion(error) }
                auth.deleteCurrentUser { [self] error in
                    if let error { return completion(error) }
                    settings.clear()
                    records.clearLocalRecords()
                    completion(nil)
                }
            }
        }
    }
}
