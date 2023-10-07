//
//  DashboardManagerSwiftUI.swift
//  ClashX Meta
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Cocoa
import RxSwift
#if SwiftUI_Version
import ClashX_Dashboard
#endif


class DashboardManager: NSObject {
	static let shared = DashboardManager()
	
	override init() {
	}
	
#if SwiftUI_Version
	let enableSwiftUI = true
	var useYacd = MenuItemFactory.useYacdDashboard {
		didSet {
			if useYacd {
				deinitNotifications()
				dashboardWindowController?.close()
			} else {
				clashWebWindowController?.close()
			}
		}
	}
	var dashboardWindowController: DashboardWindowController?
#else
	let enableSwiftUI = false
	var useYacd = true
#endif
	
	private var disposables = [Disposable]()
	
	
	var clashWebWindowController: ClashWebViewWindowController?

	func show(_ sender: NSMenuItem?) {
#if SwiftUI_Version
		initNotifications()
		
		if useYacd {
			dashboardWindowController = nil
			showWebWindow(sender)
		} else {
			clashWebWindowController = nil
			showSwiftUIWindow(sender)
		}
#else
		showWebWindow(sender)
#endif
	}
	
	func showWebWindow(_ sender: NSMenuItem?) {
		if clashWebWindowController == nil {
			clashWebWindowController = ClashWebViewWindowController.create()
			clashWebWindowController?.onWindowClose = {
				[weak self] in
				self?.clashWebWindowController = nil
			}
		}
		clashWebWindowController?.showWindow(sender)
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

#if SwiftUI_Version
extension DashboardManager {
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
	
}
#endif
