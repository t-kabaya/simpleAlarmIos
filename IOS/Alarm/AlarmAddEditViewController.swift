import UIKit
import Foundation
import MediaPlayer

class AlarmAddEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tableView: UITableView!
    
    var alarmScheduler: AlarmSchedulerDelegate = Scheduler()
    var segueInfo: SegueInfo!
    var snoozeEnabled: Bool = false
    var enabled: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        snoozeEnabled = segueInfo.snoozeEnabled
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func saveEditAlarm(_ sender: AnyObject) {
        let isNewAlarm = segueInfo.alarm == nil
        if isNewAlarm {
            let date = Scheduler.correctSecondComponent(date: datePicker.date)
            
            let alarm = AlarmInfo(
                id: UUID().uuidString,
                date: date,
                enabled: true,
                snoozeEnabled: segueInfo.snoozeEnabled,
                repeatWeekdays: segueInfo.repeatWeekdays,
                mediaID: segueInfo.mediaID,
                mediaLabel: segueInfo.mediaLabel,
                label: segueInfo.label,
                onSnooze: false,
                soundName: "bell"
            )
            
            AlarmUserDefaults.addNewAlarm(alarmModel: alarm)
            Scheduler.setNotifWithDate(alarm: alarm)
            
        } else {
            let alarms: [AlarmInfo] = AlarmUserDefaults.getAllAlarms()
            var newAlarms: [AlarmInfo] = []
            // REFACTOR map関数で書き換え
            var indexforLoop = 0
            for value in alarms {
                if value.id == segueInfo.alarm?.id {
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
            
            AlarmUserDefaults.saveAllAlarms(alarms: newAlarms)
            AlarmLogic.refrectChange()
        }
        self.performSegue(withIdentifier: Id.saveSegueIdentifier, sender: self)
    }
    
 
    func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        if segueInfo.isEditMode {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 1
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: Id.settingIdentifier)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: Id.settingIdentifier)
        }
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell!.textLabel!.text = "Repeat"
                cell!.detailTextLabel!.text = WeekdaysViewController.repeatText(weekdays: segueInfo.repeatWeekdays)
                cell!.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            } else if indexPath.row == 1 {
                cell!.textLabel!.text = "Label"
                cell!.detailTextLabel!.text = segueInfo.label
                cell!.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            } else if indexPath.row == 2 {
                cell!.textLabel!.text = "Sound"
                cell!.detailTextLabel!.text = segueInfo.mediaLabel
                cell!.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            } else if indexPath.row == 3 {
                cell!.textLabel!.text = "Snooze"
                let sw = UISwitch(frame: CGRect())
                sw.addTarget(self, action: #selector(AlarmAddEditViewController.snoozeSwitchTapped(_:)), for: UIControlEvents.touchUpInside)
                
                if snoozeEnabled {
                   sw.setOn(true, animated: false)
                }
                
                cell!.accessoryView = sw
            }
        } else if indexPath.section == 1 {
            cell = UITableViewCell(
                style: UITableViewCellStyle.default, reuseIdentifier: Id.settingIdentifier)
            cell!.textLabel!.text = "Delete Alarm"
            cell!.textLabel!.textAlignment = .center
            cell!.textLabel!.textColor = UIColor.red
        }
        
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: Id.weekdaysSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 1:
                performSegue(withIdentifier: Id.labelSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 2:
                performSegue(withIdentifier: Id.soundSegueIdentifier, sender: self)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            default:
                break
            }
        } else if indexPath.section == 1 { // alarmを削除する
            AlarmLogic.deleteAlarmById(alarmId: segueInfo.alarmUuid)
            performSegue(withIdentifier: Id.saveSegueIdentifier, sender: self)
        }
            
    }
   
    @IBAction func snoozeSwitchTapped (_ sender: UISwitch) {
        snoozeEnabled = sender.isOn
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == Id.saveSegueIdentifier {
            let dist = segue.destination as! MainAlarmViewController
            let cells = dist.tableView.visibleCells
            for cell in cells {
                let sw = cell.accessoryView as! UISwitch
                if sw.tag > segueInfo.curCellIndex {
                    sw.tag -= 1
                }
            }
            alarmScheduler.reSchedule()
        } else if segue.identifier == Id.soundSegueIdentifier {
            //TODO
            let dist = segue.destination as! MediaViewController
            dist.mediaID = segueInfo.mediaID
            dist.mediaLabel = segueInfo.mediaLabel
        } else if segue.identifier == Id.labelSegueIdentifier {
            let dist = segue.destination as! LabelEditViewController
            dist.label = segueInfo.label
        } else if segue.identifier == Id.weekdaysSegueIdentifier {
            let dist = segue.destination as! WeekdaysViewController
            dist.weekdays = segueInfo.repeatWeekdays
        }
    }
    
    @IBAction func unwindFromLabelEditView(_ segue: UIStoryboardSegue) {
        let src = segue.source as! LabelEditViewController
        segueInfo.label = src.label
    }
    
    @IBAction func unwindFromWeekdaysView(_ segue: UIStoryboardSegue) {
        let src = segue.source as! WeekdaysViewController
        segueInfo.repeatWeekdays = src.weekdays
    }
    
    @IBAction func unwindFromMediaView(_ segue: UIStoryboardSegue) {
        let src = segue.source as! MediaViewController
        segueInfo.mediaLabel = src.mediaLabel
        segueInfo.mediaID = src.mediaID
    }
}
