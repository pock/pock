//
//  PockTappableView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

public class PockTappableView: NSView {

    /// Core
    private var initialPosition: NSPoint?
    
    /// Overrideable
    public func didTapHandler()        { /***/ }
    public func didSwipeLeftHandler()  { /***/ }
    public func didSwipeRightHandler() { /***/ }
    
    override public func touchesBegan(with event: NSEvent) {
        /// Touches began
        super.touchesBegan(with: event)
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check if location is in self
        if self.frame.contains(location) {
            self.initialPosition = location
        }
    }
    
    override public func touchesEnded(with event: NSEvent) {
        /// Touches ended
        super.touchesEnded(with: event)
        /// Get touch
        guard let touch = event.allTouches().first else { return }
        /// Get touch location
        let location = touch.location(in: self.superview)
        /// Check if location is in self
        if self.frame.contains(location) {
            /// Check
            if location.x < initialPosition?.x ?? location.x {
                didSwipeLeftHandler()
            }else if location.x > initialPosition?.x ?? location.x {
                didSwipeRightHandler()
            }else {
                didTapHandler()
            }
        }
    }
}
