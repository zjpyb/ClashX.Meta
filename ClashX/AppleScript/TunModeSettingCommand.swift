//
//  ProxySettingCommand.swift
//  ClashXX
//
//  Created by Vince-hz on 2022/1/25.
//  Copyright © 2022 west2online. All rights reserved.
//

import Foundation
import AppKit

@objc class TunModeSettingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            scriptErrorNumber = -2
            scriptErrorString = "can't get application, try again later"
            return nil
        }
        let menuItem: NSMenuItem
        menuItem = delegate.tunModeMenuItem
        if menuItem.state == .on {
            menuItem.state = .on// 当条件为真时执行的代码
        } else {
            menuItem.state = .off// 当条件为假时执行的代码
        }
        delegate.tunMode(menuItem)
        return nil
    }
}
