//
//  HotKey.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation

public class HotKey {

	/// Target & Selector
	private var target: AnyObject?
	private var selector: Selector?

	/// Hit-count
	private var hitCount: Int = 0
	private var hitTimer: Timer?

	/// Initialiser
	public init(key: NSEvent.ModifierFlags, double: Bool = false, target: AnyObject, selector: Selector) {
		self.target = target
		self.selector = selector
		NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
			guard key == event.modifierFlags.intersection(.deviceIndependentFlagsMask) else {
				return
			}
			if double {
				self?.hitCount += 1
				self?.hitTimer?.invalidate()
				self?.hitTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false, block: { [weak self] _ in
					defer {
						self?.hitCount = 0
						self?.hitTimer = nil
					}
					guard self?.hitCount == 2 else {
						return
					}
					_ = self?.target?.perform(self?.selector)
				})
			} else {
				_ = self?.target?.perform(self?.selector)
			}
		}
	}

}
