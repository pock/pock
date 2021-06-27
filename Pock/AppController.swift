//
//  AppController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation
import Combine
import AppCenterAnalytics
import Magnet
import PockKit

internal struct MessageAction {
	internal enum Key: String {
		case none = "", esc = "\u{1b}", enter = "\r"
	}
	typealias MessageActionHandler = () -> Void
	let title: String
	let key: Key
	let action: MessageActionHandler?
	internal init(title: String, key: Key = .none, action: MessageActionHandler? = nil) {
		self.title = title
		self.key = key
		self.action = action
	}
}

// swiftlint:disable file_length
internal class AppController: NSResponder {
	
	/// Singleton
	static let shared = AppController()

	/// Double `ctrl` hotkey
	private var doubleCtrlHotKey: HotKey?
	
	/// Once (upon) a day timer
	private var onceADayTimer: Timer?
	
	/// Current window controller
	private var windowController: NSWindowController?
    
    /// Debug console controller
    private var debugConsoleController: NSWindowController?

	/// Private initialiser
	private override init() {
		super.init()
        if Preferences[.showDebugConsoleOnLaunch] {
            showDebugConsole()
        }
		if Preferences[.userDefinedPresentationMode] as PresentationMode == .undefined {
			Preferences[.userDefinedPresentationMode] = TouchBarHelper.currentPresentationMode.rawValue
		}
		TouchBarHelper.swizzleFunctions()
		registerForInternalNotifications()
		registerDoubleControlHotKey()
		prepareOnceADayTimer()
		clearTemporaryWidgetsFolder()
        startListeningForScreenLockNotifications()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Core
	private(set) var navigationController: PKTouchBarNavigationController!
	private(set) var pockTouchBarController: PockTouchBarController!

	internal var isVisible: Bool {
		return pockTouchBarController != nil && pockTouchBarController.isVisible
	}
    
    /// Listen for lock notifications
    private lazy var disposeBag = Set<AnyCancellable>()
    private func startListeningForScreenLockNotifications() {
        let notificationCenter = DistributedNotificationCenter.default()
        // listen for `screen is locked`
        notificationCenter.publisher(for: .init("com.apple.screenIsLocked")).sink { _ in
            Roger.debug("Screen is locked. Tearing down PockTouchBarController...")
            TouchBarHelper.markTouchBarAsDimmed(true)
        }.store(in: &disposeBag)
        // listen for `screen is unlocked`
        notificationCenter.publisher(for: .init("com.apple.screenIsUnlocked")).sink { _ in
            Roger.debug("Screen is unlocked. Preparing PockTouchBarController...")
            TouchBarHelper.markTouchBarAsDimmed(false)
        }.store(in: &disposeBag)
    }
	
	/// Clear tmp widgets folder
	private func clearTemporaryWidgetsFolder() {
		WidgetsInstaller().clearTemporaryWidgetsFolder()
	}
	
	/// Fetch latest versions
	internal func fetchLatestVersions(_ completion: @escaping () -> Void) {
		Updater().fetchLatestVersions(ignoreCache: true) { _, error in
			if let error = error {
				Roger.error(error)
			}
			async { [completion] in
				completion()
			}
		}
	}
	
	/// Open Website
	internal func openWebsite(_ customURL: URL? = nil) {
		guard let url = customURL ?? URL(string: "base.website_url".localized) else {
			return
		}
		NSWorkspace.shared.open(url)
	}
	
	/// Setup
	internal func prepareTouchBar() {
		pockTouchBarController = PockTouchBarController.load()
		navigationController = PKTouchBarNavigationController(rootController: pockTouchBarController)
	}

	/// Dismiss
	internal func tearDownTouchBar() {
		navigationController?.dismiss()
		pockTouchBarController = nil
		navigationController = nil
	}

	/// Reload
	@objc internal func reload(shouldFetchLatestVersions: Bool) {
		func _reload() {
			tearDownTouchBar()
			dsleep(0.1)
			prepareTouchBar()
		}
		if shouldFetchLatestVersions {
			reloadWidgets { [weak self] in
				self?.fetchLatestVersions {
					_reload()
				}
			}
		} else {
			_reload()
		}
	}
	
	/// Re-install defaults widgets
	@objc internal func reInstallDefaultWidgets() {
		let controller = WidgetsManagerViewController()
		openController(controller)
		controller.presentWidgetInstallPanel(withInitialState: .installDefault)
	}
	
	/// Reload (widgets)
	@objc internal func reloadWidgets(_ completion: @escaping () -> Void) {
		WidgetsLoader().loadInstalledWidgets { [completion] _ in
			completion()
		}
	}
	
	/// Relaunch
	@objc internal func relaunch() {
		guard let relaunchPpath = Bundle.main.path(forResource: "Relaunch", ofType: nil) else {
			return
		}
		let task = Process()
		task.launchPath = relaunchPpath
		task.arguments  = ["\(ProcessInfo.processInfo.processIdentifier)"]
		task.launch()
	}

	/// Toggle
	@objc internal func toggleVisibility() {
		if pockTouchBarController == nil {
			prepareTouchBar()
		} else {
			if navigationController.visibleController?.isVisible == true {
				if NSFunctionRow.activeFunctionRows().count > 1 {
					TouchBarHelper.markTouchBarAsDimmed(true)
				} else {
					reload(shouldFetchLatestVersions: false)
				}
			} else {
				TouchBarHelper.markTouchBarAsDimmed(false)
			}
		}
	}
	
	/// Blank Touch Bar
	internal func showEmptyTouchBarController(with state: EmptyTouchBarController.State) -> EmptyTouchBarController {
		let controller: EmptyTouchBarController = EmptyTouchBarController.load()
		controller.state = state
		controller.pushOnMainNavigationController()
		return controller
	}
	
	/// Register for internal notifications
	private func registerForInternalNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .shouldReloadPock, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(prepareOnceADayTimer), name: .shouldEnableAutomaticUpdates, object: nil)
	}

	/// Register double `ctrl` hotkey
	private func registerDoubleControlHotKey() {
		doubleCtrlHotKey = HotKey(key: .control, double: true, target: self, selector: #selector(toggleVisibility))
	}
	
	// MARK: Show messages panel to inform users about certain situations
	internal func showMessagePanelWith(
		error: Error? = nil,
		title: String? = nil,
		message: String? = nil,
		style: NSAlert.Style = .informational,
		actions: [MessageAction] = []
	) {
		precondition(actions.count <= 4, "Invalid alert actions count. `NSAlert` can only have a maximum of 3 buttons other than `cancel`")
		precondition(actions.filter({ $0.key == .esc }).count <= 1, "Invalid number of `cancel` actions. Only one is allowed.")
		let alert = NSAlert()
		alert.messageText = title ?? "alert.title.default".localized
		alert.informativeText = message ?? "alert.message.default".localized
		alert.alertStyle = style
		if actions.isEmpty {
			let cancel = alert.addButton(withTitle: "general.action.cancel".localized)
			cancel.keyEquivalent = MessageAction.Key.esc.rawValue
		} else {
			actions.forEach({
				let button = alert.addButton(withTitle: $0.title)
				button.keyEquivalent = $0.key.rawValue
			})
		}
		NSApp.activate(ignoringOtherApps: true)
		defer {
			NSApp.deactivate()
		}
		switch alert.runModal() {
		case .alertFirstButtonReturn:
			actions[0].action?()
		case .alertSecondButtonReturn:
			actions[1].action?()
		case .alertThirdButtonReturn:
			actions[2].action?()
		default:
			return
		}
	}
	
	// MARK: Open controller
	internal func openController(_ controller: NSViewController) {
		windowController?.close()
		let window = NSWindow(contentViewController: controller)
		window.delegate = self
		window.title = controller.title ?? ""
		window.miniwindowTitle = controller.title
		window.titleVisibility = .visible
		window.isReleasedWhenClosed = true
		window.styleMask.remove(.resizable)
		windowController = NSWindowController(window: window)
		windowController?.showWindow(self)
	}

}

extension AppController: NSWindowDelegate {
	func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        switch window.contentViewController {
        case is DebugConsoleViewController:
            debugConsoleController = nil
        default:
            windowController = nil
        }
	}
}

// MARK: Customization menu
extension AppController: NSTouchBarDelegate {
	
	/// Open customization menu
	@objc internal func openPockCustomizationPalette() {
		if pockTouchBarController == nil {
			return
		}
		pockTouchBarController.minimize()
		NSApp.touchBar = makeTouchBar()
		addCustomizationObservers()
		async(after: 0.375) {
			NSApp.toggleTouchBarCustomizationPalette(self)
		}
	}
	
	@objc internal func openControlStripCustomizationPalette() {
        NSApp.toggleTouchBarControlStripCustomizationPalette(nil)
	}
	
	override func makeTouchBar() -> NSTouchBar? {
		guard let controller = pockTouchBarController else {
			return nil
		}
		let touchBar = NSTouchBar()
		touchBar.delegate = self
		touchBar.customizationIdentifier = .pockTouchBarController
		touchBar.customizationAllowedItemIdentifiers = controller.allowedCustomizationIdentifiers
		return touchBar
	}
	
	func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		guard let item = pockTouchBarController.touchBar?.item(forIdentifier: identifier) else {
			Roger.error("Can't find `NSTouchBarItem` for given identifier: `\(identifier)`")
			return nil
		}
		guard let widget = item as? PKWidgetTouchBarItem else {
			return item
		}
		let widgetItem = NSCustomTouchBarItem(identifier: identifier)
		widgetItem.view = widget.viewForCustomizationPalette()
		widgetItem.customizationLabel = widget.customizationLabel
		return widgetItem
	}
	
	private func addCustomizationObservers() {
		NotificationCenter.default.addObserver(self,
											   selector: #selector(didExitCustomization(_:)),
											   name: NSNotification.Name("NSTouchBarDidExitCustomization"),
											   object: nil)
	}
	
	private func removeCustomizationObservers() {
		NotificationCenter.default.removeObserver(self,
												  name: NSNotification.Name("NSTouchBarDidExitCustomization"),
												  object: nil)
	}
	
	@objc private func didExitCustomization(_ sender: Any?) {
		NSApp.touchBar = nil
		pockTouchBarController.present()
	}
	
}

// MARK: Update once (upon) a day
extension AppController {

	private var onceADayTimeInterval: TimeInterval {
		return 86400 // (24h | 1 day)
	}
	
	private var onceADayDate: Date {
		var components = Calendar.current.dateComponents([.day, .month, .year], from: Date())
		components.hour = 11
		components.minute = 20
		return (Calendar.current.date(from: components) ?? Date()).addingTimeInterval(onceADayTimeInterval)
	}
	
	@objc private func prepareOnceADayTimer() {
		invalidateOnceADayTimer()
		guard Preferences[.checkForUpdatesOnceADay] == true else {
			Roger.debug("[ONCE_A_DAY_TIMER]: Don't need to prepare timer.")
			return
		}
		let timer = Timer(fireAt: onceADayDate, interval: onceADayTimeInterval, target: self, selector: #selector(checkForUpdates), userInfo: nil, repeats: true)
		RunLoop.current.add(timer, forMode: .common)
		onceADayTimer = timer
		Roger.debug("[ONCE_A_DAY_TIMER]: Created new timer! First fire date will be: { \(onceADayDate) }")
	}
	
	@objc private func invalidateOnceADayTimer() {
		onceADayTimer?.invalidate()
		onceADayTimer = nil
		Roger.debug("[ONCE_A_DAY_TIMER]: Invalidated timer.")
	}
	
	@objc private func checkForUpdates(_ timer: Timer?) {
		Roger.debug("[ONCE_A_DAY_TIMER]: Timer fired! Fetch latest versions…")
		fetchLatestVersions {}
	}
	
}

// MARK: Debug console
extension AppController {
    internal func showDebugConsole() {
        let windowController: NSWindowController
        let window: NSWindow
        if let current = debugConsoleController, let currentWindow = current.window {
            windowController = current
            window = currentWindow
        } else {
            let controller = DebugConsoleViewController()
            window = NSWindow(contentViewController: controller)
            window.title = controller.title ?? ""
            window.miniwindowTitle = controller.title
            window.titleVisibility = .visible
            window.isReleasedWhenClosed = true
            window.level = .normal
            windowController = NSWindowController(window: window)
            debugConsoleController = windowController
        }
        windowController.showWindow(self)
        window.delegate = self
        window.orderFrontRegardless()
        // Track event
        Analytics.trackEvent("AppController.showDebugConsole()")
    }
}
// swiftlint:enable file_length
