//
//  DateUtils.swift
//  Alarm-ios-swift
//
//  Created by IPG on 2020/12/28.
//  Copyright © 2020 LongGames. All rights reserved.
//

import Foundation

class DateUtils {
    public static func foramtDateToString(date: Date) -> String {
        // TODO: 命名がダサい。Dateをアラームの数字に変換する事をより表現出来る名前へと変更する。
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}
