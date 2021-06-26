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
    @IBOutlet private weak var autoScrollButton: NSButton!
    @IBOutlet private weak var clearButton: NSButton!
    
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
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        textView.textColor = .white
        // Action buttons
        floatingWindowButton.contentTintColor = isFloatingWindow ? .controlAccentColor : .white
        autoScrollButton.contentTintColor = isAutoScrollEnabled ? .systemBlue : .white
    }
    
    private func updateTextViewWithData(_ data: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        let shouldScroll = self.isAutoScrollEnabled && self.textView.visibleRect.maxY == self.textView.bounds.maxY
        textView.string += data
        if shouldScroll {
            self.textView.scrollToEndOfDocument(self)
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
        
        case autoScrollButton:
            isAutoScrollEnabled = !isAutoScrollEnabled
        
        case clearButton:
            textView.string = ""
            
        default:
            return
        }
    }
    
}
