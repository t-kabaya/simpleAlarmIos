//
//  MainAlarmViewController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15-2-28.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit

class MainAlarmViewController: UITableViewController{
    var alarmScheduler: AlarmSchedulerDelegate = Scheduler()
    var alarms: [AlarmInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelectionDuringEditing = true
        alarms = AlarmUserDefaults.getAllAlarms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        tableView.separatorStyle = alarms.count == 0
            ? UITableViewCellSeparatorStyle.none
            : UITableViewCellSeparatorStyle.singleLine

        return alarms.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // 編集ボタンを押した時の遷移
        performSegue(withIdentifier: Id.editSegueIdentifier,
                    sender: SegueInfo(curCellIndex: indexPath.row,
                    isEditMode: true,
                    label: alarms[indexPath.row].label,
                    mediaLabel: alarms[indexPath.row].mediaLabel,
                    mediaID: alarms[indexPath.row].mediaID,
                    repeatWeekdays: alarms[indexPath.row].repeatWeekdays,
                    enabled: alarms[indexPath.row].enabled,
                    snoozeEnabled: alarms[indexPath.row].snoozeEnabled,
                    alarmUuid: alarms[indexPath.row].id,
                    alarm: alarms[indexPath.row])
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: Id.alarmCellIdentifier)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: Id.alarmCellIdentifier)
        }
        // cell text
        cell!.selectionStyle = .none
        cell!.tag = indexPath.row
        
        let alarm: AlarmInfo = alarms[indexPath.row]
        let amAttr: [NSAttributedStringKey : Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : UIFont.systemFont(ofSize: 20.0)]
        let str = NSMutableAttributedString(string: DateUtils.foramtDateToString(date: alarm.date), attributes: amAttr)
        let timeAttr: [NSAttributedStringKey : Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : UIFont.systemFont(ofSize: 45.0)]
        str.addAttributes(timeAttr, range: NSMakeRange(0, str.length-2))
        cell!.textLabel?.attributedText = str
        cell!.detailTextLabel?.text = alarm.label
        
        // append switch button
        let sw = UISwitch(frame: CGRect())
        sw.transform = CGAffineTransform(scaleX: 0.9, y: 0.9);
        
        // tag is used to indicate which row had been touched
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(MainAlarmViewController.switchTapped(_:)), for: UIControlEvents.valueChanged)
        if alarm.enabled {
            cell!.backgroundColor = UIColor.white
            cell!.textLabel?.alpha = 1.0
            cell!.detailTextLabel?.alpha = 1.0
            sw.setOn(true, animated: false)
        } else {
            cell!.backgroundColor = UIColor.groupTableViewBackground
            cell!.textLabel?.alpha = 0.5
            cell!.detailTextLabel?.alpha = 0.5
        }
        cell!.accessoryView = sw
        
        // delete empty seperator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return cell!
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            alarms.remove(at: index)
            let cells = tableView.visibleCells
            for cell in cells {
                let sw = cell.accessoryView as! UISwitch
                //adjust saved index when row deleted
                if sw.tag > index {
                    sw.tag -= 1
                }
            }
            if alarms.count == 0 {
                self.navigationItem.leftBarButtonItem = nil
            }
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            alarmScheduler.reSchedule()
        }
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        let index = sender.tag
        var newAlarms: [AlarmInfo] = []
        // REFACTOR map関数で書き換え
        var indexforLoop = 0
        for value in alarms {
            if indexforLoop == index {
                newAlarms.append(AlarmInfo(
                    id: value.id,
                    date: value.date,
                    enabled: sender.isOn,
                    snoozeEnabled: value.snoozeEnabled,
                    repeatWeekdays: value.repeatWeekdays,
                    mediaID: value.mediaID,
                    mediaLabel: value.mediaLabel,
                    label: value.label,
                    onSnooze: value.onSnooze,
                    soundName: value.soundName
                ))
            } else {
                newAlarms.append(AlarmInfo(
                    id: value.id,
                    date: value.date,
                    enabled: value.enabled,
                    snoozeEnabled: value.snoozeEnabled,
                    repeatWeekdays: value.repeatWeekdays,
                    mediaID: value.mediaID,
                    mediaLabel: value.mediaLabel,
                    label: value.label,
                    onSnooze: value.onSnooze,
                    soundName: value.soundName
                ))
            }
            indexforLoop += 1
        }
            
        // 全ての登録をキャンセルする。
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // もう一度登録を行う。
        for alarm in newAlarms {
            Scheduler.setNotifWithDate(alarm: alarm)
        }
        // データベースに保存する。
        AlarmUserDefaults.saveAllAlarms(alarms: newAlarms)
        
        // tableViewを更新する。
        alarms = newAlarms
        tableView.reloadData()
  
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // 新規アラーム作成を押した時の遷移の準備
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let dist = segue.destination as! UINavigationController
        let addEditController = dist.topViewController as! AlarmAddEditViewController
        if segue.identifier == Id.addSegueIdentifier {
            addEditController.navigationItem.title = "追加"
            addEditController.segueInfo = SegueInfo(curCellIndex: alarms.count, isEditMode: false, label: "アラーム", mediaLabel: "ベル", mediaID: "", repeatWeekdays: [], enabled: false, snoozeEnabled: false, alarmUuid: nil, alarm: nil)
        } else if segue.identifier == Id.editSegueIdentifier {
            addEditController.navigationItem.title = "編集"
            addEditController.segueInfo = sender as! SegueInfo
        }
    }
    
    @IBAction func unwindFromAddEditAlarmView(_ segue: UIStoryboardSegue) {
        // 編集を完了した時に、再度読み込み
        alarms = AlarmUserDefaults.getAllAlarms()
        tableView.reloadData()
    }
    
    public func changeSwitchButtonState(index: Int) {
        //let info = notification.userInfo as! [String: AnyObject]
        //let index: Int = info["index"] as! Int
        alarms = [AlarmInfo(
            id: "",
            date: Date(),
            enabled: true,
            snoozeEnabled: true,
            repeatWeekdays: [1],
            mediaID: "",
            mediaLabel: "",
            label: "",
            onSnooze: true,
            soundName: "ベル"
        )]
        var alarm = alarms[index]
        if alarm.repeatWeekdays.isEmpty {
            alarm.enabled = false
        }
        let cells = tableView.visibleCells
        for cell in cells {
            if cell.tag == index {
                let sw = cell.accessoryView as! UISwitch
                if alarm.repeatWeekdays.isEmpty {
                    sw.setOn(false, animated: false)
                    cell.backgroundColor = UIColor.groupTableViewBackground
                    cell.textLabel?.alpha = 0.5
                    cell.detailTextLabel?.alpha = 0.5
                }
            }
        }
    }
}
