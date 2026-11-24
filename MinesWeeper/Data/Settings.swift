//
//  Settings.swift
//  MinesWeeper
//
//  Per-device preferences. Keys match the Android app's shared preferences.
//

import Foundation

enum Settings {
    static let defaultNumberOfMines = 15

    private static let numberOfMinesKey = "KEY_NUM_OF_MINES"
    private static let fieldSizeKey = "KEY_FIELD_SIZE"

    private static var defaults: UserDefaults { .standard }

    /// The saved mine count, or the default when nothing valid was saved.
    static var numberOfMines: Int {
        get {
            let saved = defaults.integer(forKey: numberOfMinesKey)
            return saved > 0 ? saved : defaultNumberOfMines
        }
        set { defaults.set(newValue, forKey: numberOfMinesKey) }
    }

    static var fieldSize: Int {
        get { defaults.integer(forKey: fieldSizeKey) }
        set { defaults.set(newValue, forKey: fieldSizeKey) }
    }

    static func clear() {
        defaults.removeObject(forKey: numberOfMinesKey)
        defaults.removeObject(forKey: fieldSizeKey)
    }
}
