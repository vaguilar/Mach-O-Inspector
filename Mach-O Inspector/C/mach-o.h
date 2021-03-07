//
//  mach-o.h
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

#ifndef mach_o_h
#define mach_o_h

#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <stdio.h>
#include <string.h>

const uint32_t macho_magic(const void* macho_ptr);

void macho_get_fat_arch(const void* macho_ptr, size_t index, struct fat_arch* fat_arch_ptr);

void macho_fat_header(const void* macho_ptr, struct fat_header* fat_header_ptr);

void macho_get_mach_header(const void* macho_ptr, struct mach_header* mach_header_ptr);

void macho_get_load_command(const void* macho_ptr, struct load_command* load_command_ptr);

uint32_t is_fat(const void* macho_ptr);

#endif /* mach_o_h */
