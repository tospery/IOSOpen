//
//  ViewController.swift
//  demo
//
//  Created by Feng on 2020/4/17.
//  Copyright © 2020 Zhuhao Wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var switchBtn: UISwitch!
    
    var status: VPNStatus {
        didSet(o) {
            updateConnectButton()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.status = .off
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(onVPNStatusChanged), name: kProxyServiceVPNStatusNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: kProxyServiceVPNStatusNotification, object: nil)
    }
    
    @objc func onVPNStatusChanged(){
        self.status = VpnManager.shared.vpnStatus
    }
    
    func updateConnectButton(){
        switch status {
        case .connecting:
            break
        case .disconnecting:
            break
        case .on:
            switchBtn.isOn = true
            break
        case .off:
            switchBtn.isOn = false
            break
        }
    }

    @IBAction func clickSwitch(_ sender: UISwitch) {
        if sender.isOn {
            VpnManager.shared.host = "223.247.128.211"
            VpnManager.shared.port = 65100
            VpnManager.shared.name = "test1119www"
            VpnManager.shared.dns  = "114.114.114.114"
            VpnManager.shared.password = "test1119www"
            VpnManager.shared.endtime  = 1687090004
            VpnManager.shared.connect()
        }else{
            VpnManager.shared.disconnect()
        }
    }
    
}

