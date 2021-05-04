//
//  WidgetInstaller.swift
//  Pock
//
//  Created by Pierluigi Galdi on 03/05/21.
//

import Foundation
import PockKit

internal final class WidgetInstaller {
	
	// MARK: State
	
	internal enum State {
		case dragdrop
		case install(widget: PKWidgetInfo)
		case update(widget: PKWidgetInfo)
		case installing(widget: PKWidgetInfo, progress: Double)
		case done(success: Bool)
	}
	
	// MARK: Properties
	
	private(set) var state: State = .dragdrop
	
	// MARK: Methods
	
	internal func installWidget(_ widget: PKWidgetInfo, progress: ((Double) -> Void)?, _ completion: (Bool) -> Void) {
		// TODO: Implement
	}
	
}
