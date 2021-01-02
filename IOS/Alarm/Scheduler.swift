//
//  Scheduler.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 16/1/15.
//  Copyright (c) 2016年 LongGames. All rights reserved.
//

import Foundation
import UIKit

class Scheduler {
    private func addChangeToAllNotification(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter
            .current()
            .getPendingNotificationRequests { notifications in
                completion(notifications)
        }
    }

    func setupNotificationSettings() -> UIUserNotificationSettings {
        var snoozeEnabled: Bool = false

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

    public static func correctSecondComponent(date: Date, calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)) -> Date {
        let second = calendar.component(.second, from: date)
        let d = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.second, value: -second, to: date, options: .matchStrictly)!
        return d
    }

    // 一旦このメソッドを使用したい。
    public static func setNotifWithDate(alarm: AlarmInfo) {
        if !alarm.enabled { return }

        let date: Date = alarm.date
        let weekdays: [Int] = alarm.repeatWeekdays
        let snoozeEnabled: Bool = alarm.snoozeEnabled
        let onSnooze: Bool = alarm.snoozeEnabled

        let notificationRequestId = "fooNotificationRequestId2"

        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.sound = UNNotificationSound(named: "\(alarm.soundName).mp3")
        content.launchImageName = "foo.png"
        let repeating: Bool = !weekdays.isEmpty

        // weekdaysがない時は、単発のローカル通知なので、
        let shouldRepeat = !weekdays.isEmpty || onSnooze

        var triggerDate: DateComponents
        var trigger: UNCalendarNotificationTrigger
        if !shouldRepeat { // 一回のみ
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)

            let triggerDate = DateComponents(hour: hour, minute: minute)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: shouldRepeat)
        } else if onSnooze { // スヌーズがオンのローカル通知を受信した時。
            // CARE: このif文の中は適当に記述している。 .minucteでは狙った挙動にはならない。
            triggerDate =  Calendar.current.dateComponents([.minute ], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                     repeats: true)
        } else { // 毎週の通知
            triggerDate =  Calendar.current.dateComponents([.weekday, .hour, .minute], from: date) // 毎週x曜日x時x分に繰り返す。
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
    }
}
