//
//  AlarmLogic.swift
//  Alarm-ios-swift
//
//  Created by IPG on 2020/12/31.
//  Copyright © 2020 LongGames. All rights reserved.
//

import Foundation
import UIKit

class AlarmLogic {
    public static func deleteAlarmById(alarmId: String?) {
        AlarmUserDefaults.deleteAlarmById(id: alarmId)
        
        // 全ての登録をキャンセルする。
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let alarms = AlarmUserDefaults.getAllAlarms()
        // 全てのプッシュ通知の登録を行う。
        for alarm in alarms {
            Scheduler.setNotifWithDate(alarm: alarm)
        }
    }
}
