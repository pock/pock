//
//  DispatchQueue-Extensions.swift
//  Pock
//
//  Created by Pierluigi Galdi on 10/03/21.
//

import Foundation

func dsleep(_ timeInterval: TimeInterval) {
	Thread.sleep(forTimeInterval: timeInterval)
}

func async(_ block: @escaping () -> Void) {
	DispatchQueue.main.async {
		block()
	}
}

func async(after: TimeInterval, _ block: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + after) {
		block()
	}
}

func background(qos: DispatchQoS.QoSClass = .background, _ block: @escaping () -> Void) {
	DispatchQueue.global(qos: qos).async {
		block()
	}
}

func background(after: TimeInterval, qos: DispatchQoS.QoSClass = .background, _ block: @escaping () -> Void) {
	DispatchQueue.global(qos: qos).asyncAfter(deadline: .now() + after) {
		block()
	}
}
