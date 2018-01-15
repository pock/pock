//
//  InjectInstaller.h
//  Pock
//
//  Created by Pierluigi Galdi on 14/01/18.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PockInjectConstants.h"

@interface InjectInstaller : NSObject <PockInjectInstallerProtocol, NSXPCListenerDelegate>
@property (nonatomic, strong) NSXPCListener *listener;
- (void)run;
@end
