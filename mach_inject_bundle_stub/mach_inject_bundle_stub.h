//
//  mach_inject_bundle_stub.h
//  macSubstrate
//
//  Created by GoKu on 28/09/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

//  mach_inject_bundle_stub.h semver:1.3.0
//  Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//  Some rights reserved: http://opensource.org/licenses/mit
//  https://github.com/rentzsch/mach_inject
//
//  Design inspired by SCPatchLoader by Jon Gotow of St. Clair Software:
//  http://www.stclairsoft.com

#ifndef mach_inject_bundle_stub_h
#define mach_inject_bundle_stub_h

#include <stdio.h>
#include <stddef.h>

typedef	struct {
    ptrdiff_t	codeOffset;
    char		bundlePackageFileSystemRepresentation[1];
} mach_inject_bundle_stub_param;

#endif /* mach_inject_bundle_stub_h */
