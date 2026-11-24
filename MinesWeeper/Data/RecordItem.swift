//
//  RecordItem.swift
//  MinesWeeper
//
//  A finished game, stored in the Realtime Database at users/<uid>/<auto id>. Field names and
//  types match RemoteRecordItem in the Android app and the database rules in that repo.
//

import Foundation

struct RecordItem: Equatable {
    var numberOfMines: Int
    var fieldSize: Int
    var timeInSeconds: Int
    /// Milliseconds since 1970, like System.currentTimeMillis() on Android.
    var timeStamp: Int64

    var dictionary: [String: Any] {
        [
            "numberOfMines": numberOfMines,
            "fieldSize": fieldSize,
            "timeInSeconds": timeInSeconds,
            "timeStamp": timeStamp,
        ]
    }

    init(numberOfMines: Int, fieldSize: Int, timeInSeconds: Int, timeStamp: Int64) {
        self.numberOfMines = numberOfMines
        self.fieldSize = fieldSize
        self.timeInSeconds = timeInSeconds
        self.timeStamp = timeStamp
    }

    /// Parses a record read from the database; returns nil for malformed data.
    init?(dictionary: [String: Any]) {
        guard let mines = (dictionary["numberOfMines"] as? NSNumber)?.intValue,
              let size = (dictionary["fieldSize"] as? NSNumber)?.intValue,
              let time = (dictionary["timeInSeconds"] as? NSNumber)?.intValue,
              let stamp = (dictionary["timeStamp"] as? NSNumber)?.int64Value else { return nil }
        self.init(numberOfMines: mines, fieldSize: size, timeInSeconds: time, timeStamp: stamp)
    }
}
