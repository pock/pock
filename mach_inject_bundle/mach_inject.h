//
//  mach_inject.h
//  macSubstrate
//
//  Created by GoKu on 28/09/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

//  mach_inject.h semver:1.3.0
//  Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//  Some rights reserved: http://opensource.org/licenses/mit
//  https://github.com/rentzsch/mach_inject

#ifndef mach_inject_h
#define mach_inject_h

#include <stdio.h>
#include <stddef.h>
#include <sys/types.h>
#include <mach/error.h>
#include <mach/vm_types.h>

#define	err_threadEntry_image_not_found     (err_local|1)

#define	INJECT_ENTRY		    injectEntry
#define	INJECT_ENTRY_SYMBOL     "injectEntry"

typedef	void (*mach_inject_entry)(ptrdiff_t codeOffset, void *paramBlock, size_t paramSize, void *dummy_pthread_data);

__BEGIN_DECLS

/*******************************************************************************
	Starts executing threadEntry in a new thread in the process specified by
	targetProcess.
	
	@param	threadEntry		->	Required pointer to injected thread's entry point.
	@param	paramBlock		->	Optional pointer to block of memory to pass to the injected thread.
	@param	paramSize		->	Optional size of paramBlock.
	@param	targetProcess	->	Required target process ID.
	@param	stackSize		->	Optional stack size of threadEntry's thread. Set to zero for default (currently 8K usable).
	@result					<-	mach_error_t
 
	***************************************************************************/
mach_error_t mach_inject(const mach_inject_entry    threadEntry,
                         const void                 *paramBlock,
                         size_t                     paramSize,
                         pid_t                      targetProcess,
                         vm_size_t                  stackSize);

/*******************************************************************************
	Given a pointer, returns its Mach-O image and image size.
	
	@param	pointer			->	Required pointer.
	@param	image			<-	Optional returned pointer to image (really a mach_header).
	@param	size			<-	Optional returned size of the image.
	@param  jumpTableOffset <-  Optional returned offset of jump table within image (useful on intel).
	@param  jumpTableSize	<-  Optional returned size of jump table (useful on intel).
	@result					<-	mach_error_t
	
	***************************************************************************/
mach_error_t machImageForPointer(const void         *pointer,
                                 const void         **image,
                                 unsigned long      *size,
                                 unsigned int       *jumpTableOffset,
                                 unsigned int       *jumpTableSize);

__END_DECLS

#endif /* mach_inject_h */
