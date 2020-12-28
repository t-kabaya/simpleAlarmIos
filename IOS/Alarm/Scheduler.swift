//
//  Scheduler.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 16/1/15.
//  Copyright (c) 2016年 LongGames. All rights reserved.
//

import Foundation
import UIKit


class Scheduler: AlarmSchedulerDelegate {
    var alarmModel: Alarms = Alarms()
    
    private func addChangeToAllNotification(completion: @escaping ([UNNotificationRequest]) -> Void) -> Void {
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { notifications in
                completion(notifications)
        }
    }

    func setupNotificationSettings() -> UIUserNotificationSettings {
        var snoozeEnabled: Bool = false
        
        addChangeToAllNotification() { notifications in
//            if let result = minFireDateWithIndex(notifications: notifications) {
//                let i = result.1
//                snoozeEnabled = alarmModel.alarms[i].snoozeEnabled
//            }
        }

        // Specify the notification types.
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.sound]
        
        // Specify the notification actions.
        let stopAction = UIMutableUserNotificationAction()
        stopAction.identifier = Id.stopIdentifier
        stopAction.title = "OK"
        stopAction.activationMode = UIUserNotificationActivationMode.background
        stopAction.isDestructive = false
        stopAction.isAuthenticationRequired = false
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = Id.snoozeIdentifier
        snoozeAction.title = "Snooze"
        snoozeAction.activationMode = UIUserNotificationActivationMode.background
        snoozeAction.isDestructive = false
        snoozeAction.isAuthenticationRequired = false
        
        let actionsArray = snoozeEnabled ? [UIUserNotificationAction](arrayLiteral: snoozeAction, stopAction) : [UIUserNotificationAction](arrayLiteral: stopAction)
        let actionsArrayMinimal = snoozeEnabled ? [UIUserNotificationAction](arrayLiteral: snoozeAction, stopAction) : [UIUserNotificationAction](arrayLiteral: stopAction)
        // Specify the category related to the above actions.
        let alarmCategory = UIMutableUserNotificationCategory()
        alarmCategory.identifier = "myAlarmCategory"
        alarmCategory.setActions(actionsArray, for: .default)
        alarmCategory.setActions(actionsArrayMinimal, for: .minimal)
        
        
        let categoriesForSettings = Set(arrayLiteral: alarmCategory)
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
        UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
        return newNotificationSettings
    }
    
    // correctDateに渡されるweekdaysが何なのかが分からない。
    private func correctDate(_ date: Date, onWeekdaysForNotify weekdays: [Int]) -> [Date] {
        if weekdays.isEmpty { // no repeat
            return [date]
        }
        var correctedDate: [Date] = [Date]()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let flags: NSCalendar.Unit = [NSCalendar.Unit.weekday, NSCalendar.Unit.weekdayOrdinal, NSCalendar.Unit.day]
        let dateComponents = (calendar as NSCalendar).components(flags, from: date)
        let weekday: Int = dateComponents.weekday!

       // repeat
        let daysInWeek = 7
        for wd in weekdays {
            
            var wdDate: Date!
            //schedule on next week
            if compare(weekday: wd, with: weekday) == .before {
                wdDate =  (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: wd+daysInWeek-weekday, to: date, options:.matchStrictly)!
            }
            //schedule on today or next week
            else if compare(weekday: wd, with: weekday) == .same {
                //scheduling date is eariler than current date, then schedule on next week
                if date.compare(now) == ComparisonResult.orderedAscending {
                    wdDate = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: daysInWeek, to: date, options:.matchStrictly)!
                }
                else { //later
                    wdDate = date
                }
            }
            //schedule on next days of this week
            else { //after
                wdDate =  (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: wd-weekday, to: date, options:.matchStrictly)!
            }
            
            //fix second component to 0
            wdDate = Scheduler.correctSecondComponent(date: wdDate, calendar: calendar)
            correctedDate.append(wdDate)
        }
        
        return correctedDate
    }
    
    public static func correctSecondComponent(date: Date, calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian))->Date {
        let second = calendar.component(.second, from: date)
        let d = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.second, value: -second, to: date, options:.matchStrictly)!
        return d
    }
    
    struct AlarmInfo {
        let id: Int
        let date: Date
        let weekdays: [Int] // 1 = 日曜日、2 = 月曜日
        let snoozeEnabled: Bool
        // let onSnooze: Bool // snoozeがonのローカル通知が
        let soundName: String
    }
    
    internal func setNotificationWithDate(_ date: Date, onWeekdaysForNotify weekdays:[Int], snoozeEnabled:Bool,  onSnooze: Bool, soundName: String, index: Int) {
        let notificationRequestId = "fooNotificationRequestId"

        // Create the content of a notification
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
//        content.sound = soundName + ".mp3"
        let repeating: Bool = !weekdays.isEmpty
        content.userInfo = ["snooze" : snoozeEnabled, "index": index, "soundName": soundName, "repeating" : repeating]
        
        // TODO: onSnoozeが何を示しているかが分からない。
        // onSnoozeは、スヌーズをオンにした、ローカル通知がアプリに届いた時のみtrueになる。
        // weekdaysがない時は、単発のローカル通知なので、
        let shouldRepeat = weekdays.isEmpty || onSnooze
//        content.subtitle = "サブタイトル"
//        content.body = "本文"
        var triggerDate: DateComponents
        var trigger: UNCalendarNotificationTrigger
        if !shouldRepeat {
            triggerDate =  Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date as Date)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                                       repeats: shouldRepeat)
        } else if onSnooze { // スヌーズがオンのローカル通知を受信した時。
            // CARE: このif文の中は適当に記述している。 .minuteでは狙った挙動にはならない。
            triggerDate =  Calendar.current.dateComponents([.minute,], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                     repeats: true)
        } else { // 毎週の通知
            triggerDate =  Calendar.current.dateComponents([.weekday,.hour,.minute], from: date) // 毎週x曜日x時x分に繰り返す。
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                     repeats: true)
        }

        // ローカル通知を登録します。
        let request = UNNotificationRequest(identifier: notificationRequestId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
          if let error = error {
            print("Error: \(error.localizedDescription)")
          } else {
            print("Scheduled notification")
          }
        }

        let datesForNotification = [date]
        

        syncAlarmModel()
        for d in datesForNotification {
            if onSnooze {
                alarmModel.alarms[index].date = Scheduler.correctSecondComponent(date: alarmModel.alarms[index].date)
            }
            else {
                alarmModel.alarms[index].date = d
            }
//            UIApplication.shared.scheduleLocalNotification(AlarmNotification)
        }
        setupNotificationSettings()

    }
    
    func setNotificationForSnooze(snoozeMinute: Int, soundName: String, index: Int) {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let snoozeTime = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: snoozeMinute, to: now, options:.matchStrictly)!
        setNotificationWithDate(snoozeTime, onWeekdaysForNotify: [Int](), snoozeEnabled: true, onSnooze:true, soundName: soundName, index: index)
    }
    
    func reSchedule() {
        //cancel all and register all is often more convenient
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        syncAlarmModel()
//        for i in 0..<alarmModel.count{
//            let alarm = alarmModel.alarms[i]
//            if alarm.enabled {
//                setNotificationWithDate(alarm.date as Date, onWeekdaysForNotify: alarm.repeatWeekdays, snoozeEnabled: alarm.snoozeEnabled, onSnooze: false, soundName: alarm.mediaLabel, index: i)
//            }
//        }
    }
    
    // workaround for some situation that alarm model is not setting properly (when app on background or not launched)
    func checkNotification() {
        alarmModel = Alarms()
        
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { (notifications) in
                if notifications.isEmpty {
                    for i in 0..<self.alarmModel.count {
                        self.alarmModel.alarms[i].enabled = false
                    }
                } else {
                    for (i, alarm) in self.alarmModel.alarms.enumerated() {
                        var isOutDated = true
                        if alarm.onSnooze {
                            isOutDated = false
                        }
                        for n in notifications {
//                            if alarm.date >= n.content.date {
//                                isOutDated = false
//                            }
                        }
                        if isOutDated {
                            self.alarmModel.alarms[i].enabled = false
                        }
                    }
                }
        }
    }
    
    private func syncAlarmModel() {
        alarmModel = Alarms()
    }
    
    private enum weekdaysComparisonResult {
        case before
        case same
        case after
    }
    
    // このcompareが、何を元に、before, afterを判断しているかが分からない。
    private func compare(weekday w1: Int, with w2: Int) -> weekdaysComparisonResult {
        if w1 != 1 && w2 == 1 {return .before}
        else if w1 == w2 {return .same}
        else {return .after}
    }
    
//    private func minFireDateWithIndex(notifications: [UNNotificationRequest]) -> (Date, Int)? {
//        if notifications.isEmpty { return nil }
//        let notificationRequest: UNNotificationRequest =  notifications.first!
//
//
//        var minIndex = -1
//        var minDate: Date = notifications.first!.fireDate!
//        for n in notifications {
//            let index = n.userInfo!["index"] as! Int
//            if(n.fireDate! <= minDate) {
//                minDate = n.fireDate!
//                minIndex = index
//            }
//        }
//        return (minDate, minIndex)
//    }
}
