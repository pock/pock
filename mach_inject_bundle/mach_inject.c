//
//  mach_inject.c
//  macSubstrate
//
//  Created by GoKu on 28/09/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

//  mach_inject.h semver:1.3.0
//  Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//  Some rights reserved: http://opensource.org/licenses/mit
//  https://github.com/rentzsch/mach_inject

#include "mach_inject.h"
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach/mach.h>
#include <mach-o/fat.h>
#include <mach-o/arch.h>
#include <mach/MACH_ERROR.h>
#include <sys/stat.h>
#include <sys/errno.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#define COMPILE_TIME_ASSERT(exp) { switch (0) { case 0: case (exp):; } }
#define ASSERT_CAST(CAST_TO, CAST_FROM) COMPILE_TIME_ASSERT(sizeof(CAST_TO) == sizeof(CAST_FROM))

#if defined(__i386__)
void* fixedUpImageFromImage(const void      *image,
                            unsigned long   imageSize,
                            unsigned int    jumpTableOffset,
                            unsigned int    jumpTableSize,
                            ptrdiff_t       fixUpOffset);
#endif /* __i386__ */

#define MACH_ERROR(msg, err) { if (err != err_none) mach_error(msg, err); }

#pragma mark - Interface

mach_error_t mach_inject(const mach_inject_entry	threadEntry,
                         const void                 *paramBlock,
                         size_t                     paramSize,
                         pid_t                      targetProcess,
                         vm_size_t                  stackSize)
{
    assert(threadEntry);
    assert(targetProcess > 0);
    assert(stackSize == 0 || stackSize > 1024);
    
    // Find the image.
    const void		*image;
    unsigned long	imageSize;
    unsigned int	jumpTableOffset;
    unsigned int	jumpTableSize;
    mach_error_t	err = machImageForPointer(threadEntry, &image, &imageSize, &jumpTableOffset, &jumpTableSize);
    
    // Initialize stackSize to default if requested.
    if (stackSize == 0)
    /** @bug
     We only want an 8K default, fix the plop-in-the-middle code below.
     */
        stackSize = 16 * 1024;
    
    // Convert PID to Mach Task ref.
    mach_port_t	remoteTask = 0;
    if (!err) {
        err = task_for_pid(mach_task_self(), targetProcess, &remoteTask);
#if defined(__i386__) || defined(__x86_64__)
        if (err == 5) fprintf(stderr, "Could not access task for pid %d. You probably need to add user to procmod group\n", targetProcess);
#endif
    }
    
    /** @todo
     Would be nice to just allocate one block for both the remote stack
     *and* the remoteCode (including the parameter data block once that's written).
     */
    
    // Allocate the remoteStack.
    vm_address_t remoteStack = (vm_address_t)NULL;
    if (!err)
        err = vm_allocate(remoteTask, &remoteStack, stackSize, 1);
    
    // Allocate the code.
    vm_address_t remoteCode = (vm_address_t)NULL;
    if (!err)
        err = vm_allocate(remoteTask, &remoteCode, imageSize, 1);
    if (!err)
        err = vm_protect(remoteTask, remoteCode, imageSize, 0, VM_PROT_EXECUTE | VM_PROT_WRITE | VM_PROT_READ);
    if (!err) {
        ASSERT_CAST(pointer_t, image);
#if defined(__ppc__) || defined(__ppc64__) || defined(__x86_64__)
        err = vm_write(remoteTask, remoteCode, (pointer_t)image, (mach_msg_type_number_t)imageSize);
#elif defined(__i386__)
        // on x86, jump table use relative jump instructions (jmp), which means
        // the offset needs to be corrected. We thus copy the image and fix the offset by hand.
        ptrdiff_t fixUpOffset = (ptrdiff_t)(image - remoteCode);
        void *fixedUpImage = fixedUpImageFromImage(image, imageSize, jumpTableOffset, jumpTableSize, fixUpOffset);
        err = vm_write(remoteTask, remoteCode, (pointer_t)fixedUpImage, (mach_msg_type_number_t)imageSize);
        free(fixedUpImage);
#endif
    }
    
    // Allocate the paramBlock if specified.
    vm_address_t remoteParamBlock = (vm_address_t)NULL;
    if (!err && paramBlock != NULL && paramSize) {
        err = vm_allocate(remoteTask, &remoteParamBlock, paramSize, 1);
        if (!err) {
            ASSERT_CAST(pointer_t, paramBlock);
            err = vm_write(remoteTask, remoteParamBlock, (pointer_t)paramBlock, (mach_msg_type_number_t)paramSize);
        }
    }
    
    // Calculate offsets.
    ptrdiff_t threadEntryOffset = 0, imageOffset = 0;
    if (!err) {
        ASSERT_CAST(void*, threadEntry);
        threadEntryOffset = ((void*)threadEntry) - image;
        
#if defined(__x86_64__)
        imageOffset = 0; // RIP-relative addressing
#else
        // WARNING: See bug https://github.com/rentzsch/mach_star/issues/11 . Not sure about this.
        imageOffset = 0;
#endif
    }
    
    // Allocate the thread.
    thread_act_t remoteThread;
#if defined(__ppc__) || defined(__ppc64__)
    if (!err) {
        ppc_thread_state_t remoteThreadState;
        
        /** @bug
         Stack math should be more sophisticated than this (ala redzone).
         */
        remoteStack += stackSize / 2;
        
        bzero(&remoteThreadState, sizeof(remoteThreadState));
        
        ASSERT_CAST(unsigned int, remoteCode);
        remoteThreadState.__srr0 = (unsigned int)remoteCode;
        remoteThreadState.__srr0 += threadEntryOffset;
        assert(remoteThreadState.__srr0 < (remoteCode + imageSize));
        
        ASSERT_CAST(unsigned int, remoteStack);
        remoteThreadState.__r1 = (unsigned int)remoteStack;
        
        ASSERT_CAST(unsigned int, imageOffset);
        remoteThreadState.__r3 = (unsigned int)imageOffset;
        
        ASSERT_CAST(unsigned int, remoteParamBlock);
        remoteThreadState.__r4 = (unsigned int)remoteParamBlock;
        
        ASSERT_CAST(unsigned int, paramSize);
        remoteThreadState.__r5 = (unsigned int)paramSize;
        
        ASSERT_CAST(unsigned int, 0xDEADBEEF);
        remoteThreadState.__lr = (unsigned int)0xDEADBEEF;
        
        err = thread_create_running(remoteTask, PPC_THREAD_STATE, (thread_state_t) &remoteThreadState, PPC_THREAD_STATE_COUNT, &remoteThread);
    }
#elif defined(__i386__)
    if (!err) {
        i386_thread_state_t remoteThreadState;
        bzero(&remoteThreadState, sizeof(remoteThreadState));
        
        vm_address_t dummy_thread_struct = remoteStack;
        remoteStack += (stackSize / 2); // this is the real stack
        // (*) increase the stack, since we're simulating a CALL instruction, which normally pushes return address on the stack.
        remoteStack -= 4;
        
#define PARAM_COUNT 4
#define STACK_CONTENTS_SIZE ((1+PARAM_COUNT) * sizeof(unsigned int))
        unsigned int stackContents[1 + PARAM_COUNT]; // 1 for the return address and 1 for each param
        // first entry is return address (see above *)
        stackContents[0] = 0xDEADBEEF; // invalid return address.
        // then we push function parameters one by one.
        stackContents[1] = imageOffset;
        stackContents[2] = remoteParamBlock;
        stackContents[3] = paramSize;
        // We use the remote stack we allocated as the fake thread struct. We should probably use a dedicated memory zone.
        // We don't fill it with 0, vm_allocate did it for us
        stackContents[4] = dummy_thread_struct;
        
        // push stackContents
        vm_write(remoteTask, remoteStack, (pointer_t)stackContents, STACK_CONTENTS_SIZE);
        
        // set remote Program Counter
        remoteThreadState.__eip = (unsigned int)remoteCode;
        remoteThreadState.__eip += threadEntryOffset;
        
        // set remote Stack Pointer
        ASSERT_CAST(unsigned int, remoteStack);
        remoteThreadState.__esp = (unsigned int)remoteStack;
        
        // create thread and launch it
        err = thread_create_running(remoteTask, i386_THREAD_STATE, (thread_state_t) &remoteThreadState, i386_THREAD_STATE_COUNT, &remoteThread);
    }
#elif defined(__x86_64__)
    if (!err) {
        x86_thread_state64_t remoteThreadState;
        bzero(&remoteThreadState, sizeof(remoteThreadState));
        
        vm_address_t dummy_thread_struct = remoteStack;
        remoteStack += (stackSize / 2); // this is the real stack
        // (*) increase the stack, since we're simulating a CALL instruction, which normally pushes return address on the stack.
        remoteStack -= 8;
        
#define PARAM_COUNT 0
#define STACK_CONTENTS_SIZE ((1+PARAM_COUNT) * sizeof(unsigned long long))
        unsigned long long stackContents[1 + PARAM_COUNT]; // 1 for the return address and 1 for each param
        // first entry is return address (see above *)
        stackContents[0] = 0x00000DEADBEA7DAD; // invalid return address.
        
        // push stackContents
        vm_write(remoteTask, remoteStack, (pointer_t)stackContents, STACK_CONTENTS_SIZE);
        
        remoteThreadState.__rdi = (unsigned long long)imageOffset;
        remoteThreadState.__rsi = (unsigned long long)remoteParamBlock;
        remoteThreadState.__rdx = (unsigned long long)paramSize;
        remoteThreadState.__rcx = (unsigned long long)dummy_thread_struct;
        
        // set remote Program Counter
        remoteThreadState.__rip = (unsigned long long)remoteCode;
        remoteThreadState.__rip += threadEntryOffset;
        
        // set remote Stack Pointer
        ASSERT_CAST(unsigned long long, remoteStack);
        remoteThreadState.__rsp = (unsigned long long)remoteStack;
        
        // create thread and launch it
        err = thread_create_running(remoteTask, x86_THREAD_STATE64, (thread_state_t) &remoteThreadState, x86_THREAD_STATE64_COUNT, &remoteThread);
    }
#else
#error architecture not supported
#endif
    
    if (err) {
        MACH_ERROR("mach_inject failing...", err);
        if (remoteParamBlock)
            vm_deallocate(remoteTask, remoteParamBlock, paramSize);
        if (remoteCode)
            vm_deallocate(remoteTask, remoteCode, imageSize);
        if (remoteStack)
            vm_deallocate(remoteTask, remoteStack, stackSize);
    }
    
    return err;
}

mach_error_t machImageForPointer(const void         *pointer,
                                 const void         **image,
                                 unsigned long      *size,
                                 unsigned int       *jumpTableOffset,
                                 unsigned int       *jumpTableSize)
{
    assert(pointer);
    assert(image);
    assert(size);
    
    unsigned long p = (unsigned long)pointer;
    
    if (jumpTableOffset && jumpTableSize) {
        *jumpTableOffset = 0;
        *jumpTableSize = 0;
    }
    
    uint32_t imageIndex, imageCount = _dyld_image_count();
    for (imageIndex = 0; imageIndex < imageCount; imageIndex++) {
#if defined(__x86_64__)
        const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(imageIndex); // why no function that returns mach_header_64
        const struct section_64 *section = getsectbynamefromheader_64(header, SEG_TEXT, SECT_TEXT);
#else
        const struct mach_header *header = (const struct mach_header *)_dyld_get_image_header(imageIndex);
        const struct section *section = getsectbynamefromheader(header, SEG_TEXT, SECT_TEXT);
#endif
        if (section == 0) continue;
        long start = section->addr + _dyld_get_image_vmaddr_slide(imageIndex);
        long stop = start + section->size;
        
        if (p >= start && p <= stop) {
            // It is truely insane we have to stat() the file system in order
            // to discover the size of an in-memory data structure.
            const char *imageName = _dyld_get_image_name(imageIndex);
            assert(imageName);
            struct stat sb;
            if (stat(imageName, &sb))
                return unix_err(errno);
            if (image) {
                ASSERT_CAST(void*, header);
                *image = (void*)header;
            }
            if (size) {
                *size = sb.st_size;
                
                // needed for Universal binaries. Check if file is fat and get image size from there.
                int fd = open(imageName, O_RDONLY);
                size_t mapSize = *size;
                char *fileImage = mmap(NULL, mapSize, PROT_READ, MAP_FILE|MAP_SHARED, fd, 0);
                
                assert(fileImage != MAP_FAILED);
                struct fat_header* fatHeader = (struct fat_header *)fileImage;
                if (fatHeader->magic == OSSwapBigToHostInt32(FAT_MAGIC)) {
                    uint32_t archCount = OSSwapBigToHostInt32(fatHeader->nfat_arch);
                    
                    NXArchInfo const *localArchInfo = NXGetLocalArchInfo();
                    
                    struct fat_arch* arch = (struct fat_arch *)(fileImage + sizeof(struct fat_header));
                    struct fat_arch* matchingArch = NULL;
                    
                    int archIndex = 0;
                    for (archIndex = 0; archIndex < archCount; archIndex++) {
                        cpu_type_t cpuType = OSSwapBigToHostInt32(arch[archIndex].cputype);
                        cpu_subtype_t cpuSubtype = OSSwapBigToHostInt32(arch[archIndex].cpusubtype);
                        
                        if (localArchInfo->cputype == cpuType) {
                            matchingArch = arch + archIndex;
                            if (localArchInfo->cpusubtype == cpuSubtype) break;
                        }
                    }
                    
                    if (matchingArch) {
                        *size = OSSwapBigToHostInt32(matchingArch->size);
                    }
                }
                
                munmap(fileImage, mapSize);
                close(fd);
            }
#if defined(__i386__) // this segment is only available on IA-32
            if (jumpTableOffset && jumpTableSize) {
                const struct section *jumpTableSection = getsectbynamefromheader(header, SEG_IMPORT, "__jump_table");
                
                if (!jumpTableSection) {
                    unsigned char *start, *end;
                    jumpTableSection = getsectbynamefromheader(header, SEG_TEXT, "__symbol_stub");
                }
                
                if (jumpTableSection) {
                    *jumpTableOffset = jumpTableSection->offset;
                    *jumpTableSize = jumpTableSection->size;
                }
            }
#endif
            return err_none;
        }
    }
    
    return err_threadEntry_image_not_found;
}

#if defined(__i386__)
void* fixedUpImageFromImage(const void      *image,
                            unsigned long   imageSize,
                            unsigned int    jumpTableOffset,
                            unsigned int    jumpTableSize,
                            ptrdiff_t       fixUpOffset)
{
    // first copy the full image
    void *fixedUpImage = (void *)malloc((size_t)imageSize);
    bcopy(image, fixedUpImage, imageSize);
    
    // address of jump table in copied image
    void *jumpTable = fixedUpImage + jumpTableOffset;
    
    /* indirect jump table */
    if (*(unsigned char *)jumpTable == 0xff) {
        // each indirect JMP instruction is 6 bytes (FF xx xx xx xx xx) where FF is the opcode for JMP
        int jumpTableCount = jumpTableSize / 6;
        
        // skip first "ff xx"
        jumpTable += 2;
        
        int entry=0;
        for (entry = 0; entry < jumpTableCount; entry++) {
            void *jmpValue = *((void **)jumpTable);
            jmpValue -= fixUpOffset;
            *((void **)jumpTable) = jmpValue;
            jumpTable+=6;
        }
    } else {
        // each JMP instruction is 5 bytes (E9 xx xx xx xx) where E9 is the opcode for JMP
        int jumpTableCount = jumpTableSize / 5;
        
        // skip first "E9"
        jumpTable++;
        
        int entry=0;
        for (entry = 0; entry < jumpTableCount; entry++) {
            unsigned int jmpValue = *((unsigned int *)jumpTable);
            jmpValue += fixUpOffset;
            *((unsigned int *)jumpTable) = jmpValue;
            jumpTable+=5;
        }
    }
    
    return fixedUpImage;
}
#endif /* __i386__ */
