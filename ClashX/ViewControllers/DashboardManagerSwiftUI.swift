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
	private let disposeBag = DisposeBag()
	private var inited = false
	static let shared = DashboardManager()
	
	override init() {
	}
	
	var dashboardWindowController: DashboardWindowController?
	
	func show(_ sender: NSMenuItem) {
		if !inited {
			inited = true
			NotificationCenter.default.rx.notification(.configFileChange).bind {
				[weak self] _ in
				self?.dashboardWindowController?.reload()
			}.disposed(by: disposeBag)

			NotificationCenter.default.rx.notification(.reloadDashboard).bind {
				[weak self] _ in
				self?.dashboardWindowController?.reload()
			}.disposed(by: disposeBag)
		}
		
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
