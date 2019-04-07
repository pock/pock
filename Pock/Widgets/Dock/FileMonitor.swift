//
//  FileMonitor.swift
//  Pock
//
//  Created by Pierluigi Galdi on 07/04/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol FileMonitorDelegate {
    func didChange(fileMonitor: FileMonitor, paths: [String])
}

class FileMonitor {
    
    private var witness:    Witness?
    private var delegate:   FileMonitorDelegate
    private var queue:      DispatchQueue
    
    public var paths: [String]
    
    init(paths: [String], queue: DispatchQueue = DispatchQueue.main, delegate: FileMonitorDelegate) {
        self.paths    = paths
        self.queue    = queue
        self.delegate = delegate
        self.startObserving()
    }
    
    deinit {
        self.witness?.flush()
    }
    
    private func startObserving() {
        self.witness = Witness(paths: paths, flags: .FileEvents, latency: 0, changeHandler: { [weak self] events in
            guard let s = self else {
                self?.witness?.flush()
                return
            }
            self?.delegate.didChange(fileMonitor: s, paths: events.map({ $0.path }))
        })
    }
}
