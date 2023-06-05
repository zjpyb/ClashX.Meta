//
//  DashboardManagerSwiftUI.swift
//  ClashX Meta
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Cocoa
import ClashX_Dashboard_Kit

class DashboardManager: NSObject {
	static let shared = DashboardManager()
	
	var dashboardWindowController: DashboardWindowController?
	
	func show(_ sender: NSMenuItem) {
		if dashboardWindowController == nil {
			dashboardWindowController = DashboardWindowController.create()
			dashboardWindowController?.onWindowClose = {
				[weak self] in
				self?.dashboardWindowController = nil
			}
		}
		
		dashboardWindowController?.set(ConfigManager.apiUrl, secret: ConfigManager.shared.overrideSecret ?? ConfigManager.shared.apiSecret)
		
		dashboardWindowController?.showWindow(sender)
	}
}
