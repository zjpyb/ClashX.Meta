//
//  DashboardManagerSwiftUI.swift
//  ClashX Meta
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Cocoa
import RxSwift
import ClashX_Dashboard

class DashboardManager: NSObject {
	
	private var disposables = [Disposable]()
	
	static let shared = DashboardManager()
	
	override init() {
	}
	
	let enableSwiftUI = true
	
	var useYacd = MenuItemFactory.useYacdDashboard {
		didSet {
			if useYacd {
				deinitNotifications()
				dashboardWindowController?.close()
			} else {
				yacdWindowController?.close()
			}
		}
	}
	
	var yacdWindowController: ClashWebViewWindowController?
	var dashboardWindowController: DashboardWindowController?
	
	func show(_ sender: NSMenuItem?) {
		initNotifications()
		
		if useYacd {
			dashboardWindowController = nil
			showWebWindow(sender)
		} else {
			yacdWindowController = nil
			showSwiftUIWindow(sender)
		}
	}
	
	func showWebWindow(_ sender: NSMenuItem?) {
		if yacdWindowController == nil {
			yacdWindowController = ClashWebViewWindowController.create()
			yacdWindowController?.onWindowClose = {
				[weak self] in
				self?.yacdWindowController = nil
			}
		}
		yacdWindowController?.showWindow(sender)
	}
	
	func showSwiftUIWindow(_ sender: NSMenuItem?) {
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
	
	func initNotifications() {
		guard !useYacd, disposables.count == 0 else { return }
		
		let n1 = NotificationCenter.default.rx.notification(.configFileChange).subscribe {
			[weak self] _ in
			self?.dashboardWindowController?.reload()
		}

		let n2 = NotificationCenter.default.rx.notification(.reloadDashboard).subscribe {
			[weak self] _ in
			self?.dashboardWindowController?.reload()
		}
		disposables.append(n1)
		disposables.append(n2)
	}
	
	func deinitNotifications() {
		disposables.forEach {
			$0.dispose()
		}
		disposables.removeAll()
	}
	
	deinit {
		deinitNotifications()
	}
}
