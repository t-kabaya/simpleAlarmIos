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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("kaba viewWillAppear")
        
        alarms = AlarmUserDefaults.getAllAlarms()
        tableView.reloadData()
        //dynamically append the edit button
        if alarms.count != 0 {
            self.navigationItem.leftBarButtonItem = editButtonItem
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
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
        if alarms.count == 0 {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
        return alarms.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            performSegue(withIdentifier: Id.editSegueIdentifier,
                        sender: SegueInfo(curCellIndex: indexPath.row,
                        isEditMode: true,
                        label: alarms[indexPath.row].label,
                        mediaLabel: alarms[indexPath.row].mediaLabel,
                        mediaID: alarms[indexPath.row].mediaID,
                        repeatWeekdays: alarms[indexPath.row].repeatWeekdays,
                        enabled: alarms[indexPath.row].enabled,
                        snoozeEnabled: alarms[indexPath.row].snoozeEnabled)
            )
        }
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
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        let index = sender.tag
        alarms[index].enabled = sender.isOn
        if sender.isOn {
            print("switch on")
            var alarm = alarms[index]
            Scheduler.setNotifWithDate(alarm: alarm)
            
            var newAlarms: [AlarmInfo] = []
            var indexforLoop = 0
            for value in alarms {
                indexforLoop += 1
                if indexforLoop == index {
                    newAlarms.append(AlarmInfo(
                        id: value.id,
                        date: value.date,
                        enabled: true,
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
                        enabled: false,
                        snoozeEnabled: value.snoozeEnabled,
                        repeatWeekdays: value.repeatWeekdays,
                        mediaID: value.mediaID,
                        mediaLabel: value.mediaLabel,
                        label: value.label,
                        onSnooze: value.onSnooze,
                        soundName: value.soundName
                    ))
                }
            }
            
            // 以下、保存処理と、schedularのキャンセル処理を書く。
            
//            alarmScheduler.setNotificationWithDate(
//                alarm.date,
//                onWeekdaysForNotify: alarm.repeatWeekdays,
//                snoozeEnabled: alarm.snoozeEnabled,
//                onSnooze: false,
//                soundName: alarm.mediaLabel,
//                index: index
//            )
            tableView.reloadData()
        } else {
            print("switch off")
            alarmScheduler.reSchedule()
            tableView.reloadData()
        }
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let dist = segue.destination as! UINavigationController
        let addEditController = dist.topViewController as! AlarmAddEditViewController
        if segue.identifier == Id.addSegueIdentifier {
            addEditController.navigationItem.title = "Add Alarm"
            addEditController.segueInfo = SegueInfo(curCellIndex: alarms.count, isEditMode: false, label: "Alarm", mediaLabel: "bell", mediaID: "", repeatWeekdays: [], enabled: false, snoozeEnabled: false)
        }
        else if segue.identifier == Id.editSegueIdentifier {
            addEditController.navigationItem.title = "Edit Alarm"
            addEditController.segueInfo = sender as! SegueInfo
        }
    }
    
    @IBAction func unwindFromAddEditAlarmView(_ segue: UIStoryboardSegue) {
        isEditing = false
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
            soundName: "bell"
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

