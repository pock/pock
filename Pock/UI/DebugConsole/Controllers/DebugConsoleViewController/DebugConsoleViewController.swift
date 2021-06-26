//
//  DebugConsoleViewController.swift
//  Pock
//
//  Created by Pierluigi Galdi on 26/06/21.
//

import Cocoa

class DebugConsoleViewController: NSViewController {
    
    // MARK: Core
    
    private lazy var lock = NSRecursiveLock()
    
    // MARK: UI Elements
    
    @IBOutlet private weak var textView: NSTextView!
    @IBOutlet private weak var floatingWindowButton: NSButton!
    @IBOutlet private weak var showOnLaunchCheckbox: NSButton!
    @IBOutlet private weak var filterTextField: NSFilterTextField!
    @IBOutlet private weak var autoScrollButton: NSButton!
    @IBOutlet private weak var clearButton: NSButton!
    
    // MARK: Data
    
    private lazy var filterQuery: String = "" {
        didSet {
            updateTextViewWithData("")
        }
    }
    private var logsData: [String] = []
    
    // MARK: Variables
    
    private var isFloatingWindow: Bool {
        get {
            return view.window?.level == .mainMenu
        }
        set {
            view.window?.level = newValue ? .mainMenu : .normal
            floatingWindowButton.contentTintColor = newValue ? .controlAccentColor : .white
        }
    }
    
    private var isAutoScrollEnabled: Bool = true {
        didSet {
            if isAutoScrollEnabled {
                textView.scrollToEndOfDocument(self)
            }
            autoScrollButton.contentTintColor = isAutoScrollEnabled ? .controlAccentColor : .white
        }
    }
    
    // MARK: Overrides
    
    override var title: String? {
        get {
            return "Pock • Debug Console"
        }
        set {
            view.window?.title = newValue ?? ""
        }
    }
    
    deinit {
        Roger.debug("** deinit **")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startListeningForConsoleEvents()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        configureUIElements()
    }
    
    private func configureUIElements() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 41/255, green: 42/255, blue: 47/255, alpha: 1).cgColor
        // TextView
        textView.textContainerInset.height = 4
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.font = NSFont(name: "Menlo", size: 12)
        textView.textColor = .white
        // Action buttons
        showOnLaunchCheckbox.state = Preferences[.showDebugConsoleOnLaunch] ? .on : .off
        floatingWindowButton.contentTintColor = isFloatingWindow ? .controlAccentColor : .white
        autoScrollButton.contentTintColor = isAutoScrollEnabled ? .systemBlue : .white
        // Tooltips
        floatingWindowButton.toolTip = "debug.console.floating-window".localized
        autoScrollButton.toolTip = "debug.console.scroll-automatically".localized
        clearButton.toolTip = "debug.console.clear-console".localized
    }
    
    private func updateTextViewWithData(_ data: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        // split per line
        let splitted = data.split(separator: "\n")
        logsData.append(contentsOf: splitted.map({ String($0) }))
        
        let shouldScroll = isAutoScrollEnabled && textView.visibleRect.maxY == textView.bounds.maxY
        let stringValue: String
        if !filterQuery.isEmpty {
            let filtered = logsData.filter({ $0.lowercased().contains(filterQuery.lowercased()) })
            filterTextField.setNumberOfOccurrencies(filtered.count)
            stringValue = filtered.joined(separator: "\n")
        } else {
            filterTextField.setNumberOfOccurrencies(0)
            stringValue = logsData.joined(separator: "\n")
        }
        textView.string = stringValue
        if shouldScroll {
            textView.scrollToEndOfDocument(self)
        }
    }
    
    private func startListeningForConsoleEvents() {
        Roger.listenForSTDOUTEvents { [weak self] incomingLogs in
            self?.updateTextViewWithData(incomingLogs)
        }
        Roger.listenForSTDERREvents { [weak self] incomingLogs in
            self?.updateTextViewWithData(incomingLogs)
        }
    }
    
    // MARK: IB Actions
    
    @IBAction private func didSelectAction(_ sender: Any?) {
        guard let control = sender as? NSControl else {
            return
        }
        switch control {
        case floatingWindowButton:
            isFloatingWindow = !isFloatingWindow
        
        case showOnLaunchCheckbox:
            Preferences[.showDebugConsoleOnLaunch] = showOnLaunchCheckbox.state == .on
            
        case filterTextField.textField:
            filterQuery = filterTextField.textField.stringValue
            
        case filterTextField.clearButton:
            filterTextField.textField.stringValue = ""
            filterQuery = ""
            view.window?.makeFirstResponder(nil)
            
        case autoScrollButton:
            isAutoScrollEnabled = !isAutoScrollEnabled
        
        case clearButton:
            logsData.removeAll()
            updateTextViewWithData("")
            
        default:
            return
        }
    }
    
}
