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
    static let persistKey: String = "alarmInfoKey2"
    
    typealias id = String
    
    public static func addNewAlarm(alarmModel: AlarmInfo) -> Void {
        // 新しくalarmを追加する。
        let alarmStr = encode(alarmModel: alarmModel)
        let alarmsStrs: [String]? = ud.array(forKey: persistKey) as? [String]
        
        if var _alarmStrs = alarmsStrs {
            _alarmStrs.append(alarmStr)
            save(alarmsStr: _alarmStrs)
        } else {
            save(alarmsStr: [alarmStr])
        }
        let allAlarms = AlarmUserDefaults.getAllAlarms()
        print("kaba allAlarms = ", allAlarms)
    }
    
    public static func getAllAlarms() -> [AlarmInfo] {
        // alarm一覧を取得する。
        guard let alarms: [String] = ud.array(forKey: persistKey) as? [String] else {return []}
        
        return alarms.map {decode(alarmStr: $0)}
    }
    
    public static func deleteAlarmById(id: String) -> Void {
        // あるidのalarmをデータベースから削除する。
        let alarms: [AlarmInfo] = getAllAlarms()
        let deletedAlarms = alarms.filter {$0.id != id}
                
        save(alarms: deletedAlarms)
    }
    
    private static func save (alarms: [AlarmInfo]) {
        let alarmsStr = alarms.map { encode(alarmModel: $0)}
        ud.set(alarmsStr, forKey: persistKey)
        ud.synchronize()
    }
    
    private static func save(alarmsStr: [String]) {
        ud.set(alarmsStr, forKey: persistKey)
        ud.synchronize()
    }
    
    private static func encode(alarmModel: AlarmInfo) -> String {
        let alarmData: Data = try! JSONEncoder().encode(alarmModel)
        return String(data: alarmData, encoding: .utf8)!
    }
    
    private static func decode(alarmStr: String) -> AlarmInfo {
        return try! JSONDecoder().decode(AlarmInfo.self, from: alarmStr.data(using: .utf8)!)
    }
}
