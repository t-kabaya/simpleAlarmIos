//
//  AlarmInfo.swift
//  Alarm-ios-swift
//
//  Created by IPG on 2020/12/28.
//  Copyright © 2020 LongGames. All rights reserved.
//

import Foundation

// AlarmModelからの移行先

struct AlarmInfo: Codable {
    let id: String
    let date: Date
    var enabled: Bool
    let snoozeEnabled: Bool
    let repeatWeekdays: [Int]
    let mediaID: String
    let mediaLabel: String
    let label: String
    let onSnooze: Bool
    let soundName: String
//    var formattedTime: String // この項目がなぜ必要なのかが分からない。
}
