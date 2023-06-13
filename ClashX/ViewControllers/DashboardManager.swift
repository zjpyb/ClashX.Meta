//
//  DashboardManagerSwiftUI.swift
//  ClashX Meta
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Cocoa

class DashboardManager: NSObject {
	static let shared = DashboardManager()
	
	let enableSwiftUI = false
	var useYacd = true

	var dashboardWindowController: ClashWebViewWindowController?
	
	func show(_ sender: NSMenuItem?) {
		if dashboardWindowController == nil {
			dashboardWindowController = ClashWebViewWindowController.create()
			dashboardWindowController?.onWindowClose = {
				[weak self] in
				self?.dashboardWindowController = nil
			}
		}
		dashboardWindowController?.showWindow(sender)
	}
}
