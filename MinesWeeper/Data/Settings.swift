//
//  Settings.swift
//  MinesWeeper
//
//  Per-device preferences. Keys match the Android app's shared preferences.
//

import Foundation

protocol GameSettings: AnyObject {
    /// The saved mine count, or the default when nothing valid was saved.
    var numberOfMines: Int { get set }
    var fieldSize: Int { get set }
    func clear()
}

final class UserDefaultsSettings: GameSettings {
    static let defaultNumberOfMines = 15

    private static let numberOfMinesKey = "KEY_NUM_OF_MINES"
    private static let fieldSizeKey = "KEY_FIELD_SIZE"

    private let defaults: UserDefaults

    /// [defaults] is injectable so tests can use a throwaway suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var numberOfMines: Int {
        get {
            let saved = defaults.integer(forKey: Self.numberOfMinesKey)
            return saved > 0 ? saved : Self.defaultNumberOfMines
        }
        set { defaults.set(newValue, forKey: Self.numberOfMinesKey) }
    }

    var fieldSize: Int {
        get { defaults.integer(forKey: Self.fieldSizeKey) }
        set { defaults.set(newValue, forKey: Self.fieldSizeKey) }
    }

    func clear() {
        defaults.removeObject(forKey: Self.numberOfMinesKey)
        defaults.removeObject(forKey: Self.fieldSizeKey)
    }
}
