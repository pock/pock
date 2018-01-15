//
//  load_bundle.c
//  macSubstrate
//
//  Created by GoKu on 28/09/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

//  load_bundle.c semver:1.3.0
//  Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//  Some rights reserved: http://opensource.org/licenses/mit
//  https://github.com/rentzsch/mach_inject

#include "load_bundle.h"
#include <CoreServices/CoreServices.h>
#include <sys/syslimits.h>
#include <mach-o/dyld.h>
#include <mach/MACH_ERROR.h>
#include <dlfcn.h>

#define MACH_ERROR(msg, err) { if (err != err_none) mach_error(msg, err); }

mach_error_t load_bundle_package(const char *bundlePackageFileSystemRepresentation)
{
    fprintf(stderr, "mach_inject_bundle load_bundle_package: %s\n", bundlePackageFileSystemRepresentation);
    assert(bundlePackageFileSystemRepresentation);
    assert(strlen(bundlePackageFileSystemRepresentation));
    
    mach_error_t err = err_none;
    
    // Morph the FSR into a URL.
    CFURLRef bundleURL = NULL;
    if (!err) {
        bundleURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
                                                            (const UInt8*)bundlePackageFileSystemRepresentation,
                                                            strlen(bundlePackageFileSystemRepresentation),
                                                            true);
        if (!bundleURL)
            err = err_load_bundle_url_from_path;
    }
    MACH_ERROR("mach error on bundle load", err);
    
    // Create bundle.
    CFBundleRef bundle = NULL;
    if (!err) {
        bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
        if (!bundle)
            err = err_load_bundle_create_bundle;
    }
    MACH_ERROR("mach error on bundle load", err);
    
    // Discover the bundle's executable file.
    CFURLRef bundleExecutableURL = NULL;
    if (!err) {
        assert(bundle);
        bundleExecutableURL = CFBundleCopyExecutableURL(bundle);
        if (!bundleExecutableURL)
            err = err_load_bundle_package_executable_url;
    }
    MACH_ERROR("mach error on bundle load", err);
    
    // Morph the executable's URL into an FSR.
    char bundleExecutableFileSystemRepresentation[PATH_MAX];
    if (!err) {
        assert(bundleExecutableURL);
        if (!CFURLGetFileSystemRepresentation(bundleExecutableURL,
                                              true,
                                              (UInt8*)bundleExecutableFileSystemRepresentation,
                                              sizeof(bundleExecutableFileSystemRepresentation))) {
            err = err_load_bundle_path_from_url;
        }
    }
    MACH_ERROR("mach error on bundle load", err);
    
    // Do the real work.
    if (!err) {
        assert(strlen(bundleExecutableFileSystemRepresentation));
        err = load_bundle_executable(bundleExecutableFileSystemRepresentation);
    }
    
    // Clean up.
    if (bundleExecutableURL)
        CFRelease(bundleExecutableURL);
    if (bundleURL)
        CFRelease(bundleURL);
#ifdef __clang_analyzer__
    if (bundle)
        CFRelease(bundle);
#endif
    
    MACH_ERROR("mach error on bundle load", err);
    return err;
}

mach_error_t load_bundle_executable(const char *bundleExecutableFileSystemRepresentation)
{
    assert(bundleExecutableFileSystemRepresentation);
    
    void *image = dlopen(bundleExecutableFileSystemRepresentation, RTLD_NOW);
    if (!image) {
        dlerror();
        return err_load_bundle_NSObjectFileImageFailure;
    }
    
    return 0;
}
