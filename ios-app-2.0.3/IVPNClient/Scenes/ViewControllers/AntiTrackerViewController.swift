//
//  AntiTrackerViewController.swift
//  IVPN iOS app
//  https://github.com/ivpn/ios-app
//
//  Created by Juraj Hilje on 2019-04-15.
//  Copyright (c) 2020 Privatus Limited.
//
//  This file is part of the IVPN iOS app.
//
//  The IVPN iOS app is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The IVPN iOS app is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License
//  along with the IVPN iOS app. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import ActiveLabel

class AntiTrackerViewController: UITableViewController {
    
    @IBOutlet weak var antiTrackerSwitch: UISwitch!
    @IBOutlet weak var antiTrackerHardcoreSwitch: UISwitch!
    
    @IBAction func toggleAntiTracker(_ sender: UISwitch) {
        if sender.isOn && Application.shared.settings.connectionProtocol.tunnelType() == .ipsec {
            showAlert(title: "IKEv2 not supported", message: "AntiTracker is supported only for OpenVPN and WireGuard protocols.") { _ in
                sender.setOn(false, animated: true)
            }
            return
        }
        
        UserDefaults.shared.set(sender.isOn, forKey: UserDefaults.Key.isAntiTracker)
        antiTrackerHardcoreSwitch.isEnabled = sender.isOn
    }
    
    @IBAction func toggleAntiTrackerHardcore(_ sender: UISwitch) {
        UserDefaults.shared.set(sender.isOn, forKey: UserDefaults.Key.isAntiTrackerHardcore)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.init(named: Theme.ivpnBackgroundQuaternary)
        antiTrackerSwitch.setOn(UserDefaults.shared.isAntiTracker, animated: false)
        antiTrackerHardcoreSwitch.setOn(UserDefaults.shared.isAntiTrackerHardcore, animated: false)
        antiTrackerHardcoreSwitch.isEnabled = UserDefaults.shared.isAntiTracker
    }

}

// MARK: - UITableViewDelegate -

extension AntiTrackerViewController {
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer = view as! UITableViewHeaderFooterView
        footer.textLabel?.textColor = UIColor.init(named: Theme.ivpnLabel6)
        
        let urlString = section > 0 ? "https://www.ivpn.net/antitracker/hardcore" : "https://www.ivpn.net/antitracker"
        
        let label = ActiveLabel(frame: .zero)
        let customType = ActiveType.custom(pattern: "Learn more")
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        label.enabledTypes = [customType]
        label.text = footer.textLabel?.text
        label.textColor = UIColor.init(named: Theme.ivpnLabel6)
        label.customColor[customType] = UIColor.init(named: Theme.ivpnBlue)
        label.handleCustomTap(for: customType) { _ in
            self.openWebPage(urlString)
        }
        footer.addSubview(label)
        footer.textLabel?.text = ""
        label.bindFrameToSuperviewBounds(leading: 16, trailing: -16)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.init(named: Theme.ivpnLabel6)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.init(named: Theme.ivpnBackgroundPrimary)
    }
    
}
