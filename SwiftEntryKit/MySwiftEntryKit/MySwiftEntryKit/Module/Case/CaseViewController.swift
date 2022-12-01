//
//  CaseViewController.swift
//  MySwiftEntryKit
//
//  Created by liaoya on 2020/7/13.
//  Copyright © 2020 杨建祥. All rights reserved.
//

import UIKit
import SWFrame
import SwifterSwift
import SwiftEntryKit

class CaseViewController: CaseListViewController {

    @objc func toast(_ parameters: [String: Any]?) {
        var attributes = EKAttributes.toast
        attributes.entryBackground = .visualEffect(style: .standard)
        
        let title = EKProperty.LabelContent(text: "", style: EKProperty.LabelStyle(font: .normal(15), color: .black))
        let description = EKProperty.LabelContent(text: "Are you ready for some testing?", style: EKProperty.LabelStyle(font: .normal(15), color: .black, alignment: .center))
        let simpleMessage = EKSimpleMessage(title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
        let contentView = EKNotificationMessageView(with: notificationMessage)
        
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    @objc func custom(_ parameters: [String: Any]?) {
        var attributes = EKAttributes.centerFloat
        attributes.windowLevel = .alerts
        attributes.displayDuration = .infinity
        attributes.screenInteraction = .absorbTouches
        attributes.entryInteraction = .absorbTouches
        attributes.screenBackground = .color(color: EKColor(light: UIColor.black.withAlphaComponent(0.3), dark: UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.entranceAnimation = .init(
            scale: .init(from: 0.9, to: 1, duration: 0.4, spring: .init(damping: 0.8, initialVelocity: 0)),
            fade: .init(from: 0, to: 1, duration: 0.3)
        )
        attributes.exitAnimation = .init(
            scale: .init(from: 1, to: 0.4, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)),
            fade: .init(from: 1, to: 0, duration: 0.2)
        )
        SwiftEntryKit.display(entry: MyCustomView(), using: attributes)
    }
    
    @objc func wifi(_ parameters: [String: Any]?) {
        var attributes = EKAttributes.centerFloat
        attributes.windowLevel = .alerts
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .absorbTouches
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled
        attributes.screenBackground = .color(color: EKColor(light: UIColor.black.withAlphaComponent(0.3), dark: UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.entranceAnimation = .init(scale: .init(from: 0.9, to: 1, duration: 0.4, spring: .init(damping: 0.8, initialVelocity: 0)), fade: .init(from: 0, to: 1, duration: 0.3))
        attributes.exitAnimation = .init(scale: .init(from: 1, to: 0.4, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)), fade: .init(from: 1, to: 0, duration: 0.2))
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .constant(value: 400))

        let title = EKProperty.LabelContent(text: "未连接WiFi", style: EKProperty.LabelStyle(font: .normal(16), color: .black, alignment: .center))
        let description = EKProperty.LabelContent(text: "请将手机连接至需要安装插件的路由器WIFI", style: EKProperty.LabelStyle(font: .normal(14), color: .init(light: UIColor(hex: 0x333333)!, dark: UIColor(hex: 0x333333)!), alignment: .center))
        let simpleMessage = EKSimpleMessage(title: title, description: description)
        let cancel = EKProperty.ButtonContent(label: .init(text: "取消", style: .init(font: .normal(16), color: .init(light: UIColor(hex: 0x333333)!, dark: UIColor(hex: 0x333333)!))), backgroundColor: .clear, highlightedBackgroundColor: .clear){
            SwiftEntryKit.dismiss()
        }
        let ok = EKProperty.ButtonContent(label: .init(text: "确定", style: .init(font: .normal(16), color: .init(light: UIColor(hex: 0x333333)!, dark: UIColor(hex: 0x333333)!))), backgroundColor: .clear, highlightedBackgroundColor: .clear){
            SwiftEntryKit.dismiss()
        }
        let buttonsBarContent = EKProperty.ButtonBarContent.init(with: [cancel, ok], separatorColor: .clear, expandAnimatedly: false)
        let alertMessage = EKAlertMessage.init(simpleMessage: simpleMessage, buttonBarContent: buttonsBarContent)
        let contentView = EKAlertMessageView(with: alertMessage)
        
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
}

class MyCustomView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
        clipsToBounds = true
        layer.cornerRadius = 5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UIView {

    @discardableResult
    func fromNib<T : UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(type(of: self).className, owner: self, options: nil)?.first as? T else {
            return nil
        }
        addSubview(contentView)
        contentView.fillSuperview()
        return contentView
    }
}
