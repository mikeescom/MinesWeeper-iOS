//
//  AppContainer.swift
//  MinesWeeper
//
//  The app's dependencies, built once at launch and handed to each screen through its
//  initializer. This plays the role Hilt's SingletonComponent plays on Android: screens depend
//  on protocols, and only this file knows the concrete Firebase and on-disk implementations.
//

import Foundation

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
}
