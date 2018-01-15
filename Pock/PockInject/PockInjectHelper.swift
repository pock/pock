//
//  PockInjectHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 13/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import SMJobKit

/// Class
class PockInjectInstaller: Client {
    override class var serviceIdentifier: String {
        return "com.pigigaldi.Pock.inject_installer"
    }
}

class PockInjectHelper: Client {
    override class var serviceIdentifier: String {
        return "com.pigigaldi.Pock.inject_helper"
    }
}

/// PockInjectManager
class PockInjectManager: NSObject {
    
    /// Shared instance
    static let shared: PockInjectManager = PockInjectManager()
    
    /// Hide init
    private override init() {
        super.init()
    }
    
    /// Notification dictionary
    static var notificationDictionary: NSMutableDictionary? {
    
        /// Read plist and return dict
        let dirPath = NSString(string: kPockBadgeLabelsPlistDir).expandingTildeInPath
        
        /// Return
        return NSMutableDictionary(contentsOfFile: "\(dirPath)/\(kPockBadgeLabelsPlistName)")
    
    }
    
    /// Get pid for bundle identifier
    class func getPID(for bundleIdentifier: String?) -> pid_t {
    
        /// Check for bundle identifier
        guard let b_id = bundleIdentifier else { return 0 }
        
        /// Create pid_t = 0
        var returnable: pid_t = 0
        
        /// Iterate on running applications from NSWorkspace
        for running_app in NSWorkspace.shared().runningApplications {
            
            /// Check if bundle-identifier is the same
            if running_app.bundleIdentifier == b_id {
                
                /// Return pid_t
                returnable = running_app.processIdentifier
                
                /// Stop for loop
                break
                
            }else { continue }
            
        }
        
        /// Return
        return returnable
    
    }
    
    /// Inject
    class func inject(into items: [DockItem]) {
    
        /// Get XPC helper connection
        let injectXPCHelperConnection = PockInjectManager.shared.getXPCHelperConnection()?.remoteObjectProxyWithErrorHandler({ error in
            
            /// Log
            NSLog("[Pock]: Can't create XPC Helper connection. Error: \(error)")
            
        }) as! PockInjectHelperProtocol
        
        /// If success, inject into running apps
        items.forEach({ item in
            
            /// Get needed info
            let internalPath = Bundle.main.path(forResource: kInjectInternalBundleName, ofType: nil)
            let pid = PockInjectManager.getPID(for: item.bundleIdentifier)
            
            /// Inject into app
            if pid > 0 {
                
                injectXPCHelperConnection.injectPlugin(internalPath, intoPID: pid, forBundleID: item.bundleIdentifier, completionBlock: { success in
                    
                    /// Log
                    NSLog("[Pock]: Injection success: \(success)")
                    
                })
                
            }
            
        })
    
    }
    
    /// XPC connections
    private var xpcInstallerConnection: NSXPCConnection?
    private var xpcHelperConnection: NSXPCConnection?
    
    /// Create installer connection
    func getXPCInstallerConnection() -> NSXPCConnection? {
        
        /// Check for nil
        if self.xpcInstallerConnection != nil {
            return self.xpcInstallerConnection
        }
        
        /// Create connection
        self.xpcInstallerConnection = NSXPCConnection(machServiceName: kInjectInstallerBundleID, options: NSXPCConnection.Options.privileged)
        self.xpcInstallerConnection?.exportedObject = self
        self.xpcInstallerConnection?.exportedInterface = NSXPCInterface(with: PockInjectInstallerProtocol.self)
        self.xpcInstallerConnection?.remoteObjectInterface = NSXPCInterface(with: PockInjectInstallerProtocol.self)
        self.xpcInstallerConnection?.invalidationHandler = {
            self.xpcInstallerConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.xpcInstallerConnection = nil
                NSLog("[Pock]: InjectInstaller XPC connection invalidated")
            }
        }
        self.xpcInstallerConnection?.resume()
        
        /// Return
        return self.xpcInstallerConnection
        
    }
    
    /// Create connection
    func getXPCHelperConnection() -> NSXPCConnection? {
        
        /// Check for nil
        if self.xpcHelperConnection != nil {
            return self.xpcHelperConnection
        }
        
        /// Create connection
        self.xpcHelperConnection = NSXPCConnection(machServiceName: kInjectHelperBundleID, options: NSXPCConnection.Options.privileged)
        self.xpcHelperConnection?.exportedObject = self
        self.xpcHelperConnection?.exportedInterface = NSXPCInterface(with: PockInjectHelperProtocol.self)
        self.xpcHelperConnection?.remoteObjectInterface = NSXPCInterface(with: PockInjectHelperProtocol.self)
        self.xpcHelperConnection?.invalidationHandler = {
            self.xpcHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.xpcHelperConnection = nil
                NSLog("[Pock]: InjectHelper XPC connection invalidated")
            }
        }
        self.xpcHelperConnection?.resume()
        
        /// Return
        return self.xpcHelperConnection
        
    }
    
}
