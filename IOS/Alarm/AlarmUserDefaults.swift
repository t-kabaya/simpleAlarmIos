//
//  AlarmUserDefaults.swift
//  Alarm-ios-swift
//
//  Created by IPG on 2020/12/27.
//  Copyright © 2020 LongGames. All rights reserved.
//

import Foundation

class AlarmUserDefaults {
    static let ud: UserDefaults = UserDefaults.standard
    static let persistKey: String = "alarmInfoKey"
    
    typealias id = String
    
    public static func save(alarmInfo: AlarmInfo) -> Void {
        let alarms: [id : AlarmInfo] = ["1" : alarmInfo]
        ud.set(alarms, forKey: persistKey)
        ud.synchronize()
    }
    
    public static func getAlarms() -> [id : AlarmInfo] {
        let alarms: [id : AlarmInfo] = ud.dictionary(forKey: persistKey) as! [id : AlarmInfo]
        return alarms
    }
}
