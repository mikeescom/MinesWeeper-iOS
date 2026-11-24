//
//  RecordRanking.swift
//  MinesWeeper
//
//  Orders records best first: higher mine density (mines per square) wins, and among equally
//  dense games the faster time wins, then the newer one. Matches RecordRanking.kt on Android.
//

import Foundation

enum RecordRanking {

    static func density(_ record: RecordItem) -> Double {
        record.fieldSize > 0 ? Double(record.numberOfMines) / Double(record.fieldSize) : 0
    }

    static func rank(_ records: [RecordItem]) -> [RecordItem] {
        records.sorted { a, b in
            let densityA = density(a)
            let densityB = density(b)
            if densityA != densityB { return densityA > densityB }
            if a.timeInSeconds != b.timeInSeconds { return a.timeInSeconds < b.timeInSeconds }
            return a.timeStamp > b.timeStamp
        }
    }
}
