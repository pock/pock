//
//  ControlCenterWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol PressableSegmentedControlDelegate: class {
    func didMove(with event: NSEvent, location: NSPoint)
}

class PressableSegmentedControl: NSSegmentedControl {
    
    /// Public
    weak var delegate: PressableSegmentedControlDelegate?
    var didPressAt: ((NSPoint) -> Void)?
    var minimumPressDuration: TimeInterval = 0.55
    
    /// Core
    private var location: NSPoint = .zero
    private var began_time: Date!
    private var timer: Timer?
    private var canMove: Bool = false
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        began_time = Date()
        location = event.allTouches().first?.location(in: self) ?? .zero
        timer = Timer.scheduledTimer(withTimeInterval: minimumPressDuration, repeats: false, block: { [unowned self] _ in
            self.canMove = true
            self.didPressAt?(self.location)
        })
    }
    
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        location = event.allTouches().first?.location(in: self) ?? .zero
        timer?.fire()
        if canMove {
            delegate?.didMove(with: event, location: location)
        }
    }
    
    override func touchesEnded(with event: NSEvent) {
        timer?.invalidate()
        canMove  = false
        location = .zero
        super.touchesEnded(with: event)
    }
}

class ControlCenterWidget: PKWidget {
    
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier.controlCenter
    var customizationLabel: String            = NSLocalizedString("Control Center", comment: "Control Center")
    var view: NSView!
    
    /// Core
    private(set) var controls: [ControlCenterItem] = []
    private var slideableController: PKSlideableController?
    
    /// Volume items
    public var volumeItems: [ControlCenterItem] {
        return controls.filter({ $0 is CCVolumeUpItem || $0 is CCVolumeDownItem })
    }
    
    /// Brightness items
    public var brightnessItems: [ControlCenterItem] {
        return controls.filter({ $0 is CCBrightnessUpItem || $0 is CCBrightnessDownItem })
    }
    
    /// UI
    fileprivate var segmentedControl: PressableSegmentedControl!
    
    required init() {
        self.controls = [
            CCBrightnessDownItem(parentWidget: self),
            CCBrightnessUpItem(parentWidget: self),
            CCVolumeDownItem(parentWidget: self),
            CCVolumeUpItem(parentWidget: self)
        ]
        self.initializeSegmentedControl()
        self.view = segmentedControl
    }
    
    private func initializeSegmentedControl() {
        let items = controls.map({ $0.icon }) as [NSImage]
        segmentedControl = PressableSegmentedControl(images: items, trackingMode: .momentary, target: self, action: #selector(tap(_:)))
        segmentedControl.delegate = self
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.autoresizingMask = [.width, .height]
        controls.enumerated().forEach({ index, _ in
            segmentedControl.setWidth(50, forSegment: index)
        })
        segmentedControl.didPressAt = { [unowned self] location in
            self.longTap(at: location)
        }
    }
    
    @objc private func tap(_ sender: NSSegmentedControl) {
        controls[sender.selectedSegment].action()
    }
    
    @objc private func longTap(at location: CGPoint) {
        let index = Int(ceil(location.x / (segmentedControl.frame.width / 4))) - 1
        guard (0..<controls.count).contains(index) else { return }
        segmentedControl.selectedSegment = index
        controls[index].longPressAction()
    }
}

extension ControlCenterWidget {
    func showSlideableController(for item: ControlCenterItem?, currentValue: Float = 0) {
        guard let item = item else { return }
        slideableController = PKSlideableController.load()
        switch item.self {
        case is CCVolumeUpItem, is CCVolumeDownItem:
            slideableController?.set(downItem: volumeItems.first, upItem: volumeItems.last)
        case is CCBrightnessUpItem, is CCBrightnessDownItem:
            slideableController?.set(downItem: brightnessItems.first, upItem: brightnessItems.last)
        default:
            return
        }
        slideableController?.set(currentValue: currentValue)
        AppDelegate.default.navController?.push(slideableController!)
    }
}

extension ControlCenterWidget: PressableSegmentedControlDelegate {
    func didMove(with event: NSEvent, location: NSPoint) {
        let slider = slideableController?.touchBar?.item(forIdentifier: NSTouchBarItem.Identifier(rawValue: "SlideItem"))
        slider?.view?.touchesBegan(with: event)
        slider?.view?.touchesMoved(with: event)
        slideableController?.set(initialLocation: location)
    }
}
