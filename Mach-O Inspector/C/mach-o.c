//
//  mach-o.c
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

#include "mach-o.h"

const uint32_t macho_magic(const void* macho_ptr) {
    return *((const uint32_t*) macho_ptr);
}

void macho_fat_header(const void* macho_ptr, struct fat_header* fat_header_ptr) {
    memcpy(fat_header_ptr, macho_ptr, sizeof(struct fat_header));
    fat_header_ptr->magic = ntohl(fat_header_ptr->magic);
    fat_header_ptr->nfat_arch = ntohl(fat_header_ptr->nfat_arch);
}

void macho_get_fat_arch(const void* macho_ptr, size_t index, struct fat_arch* fat_arch_ptr) {
    size_t offset = (sizeof(struct fat_arch) * index) + sizeof(struct fat_header);
    memcpy(fat_arch_ptr, macho_ptr + offset, sizeof(struct fat_arch));
    fat_arch_ptr->offset = ntohl(fat_arch_ptr->offset);
}

void macho_get_mach_header(const void* macho_ptr, struct mach_header* mach_header_ptr) {
    memcpy(mach_header_ptr, macho_ptr, sizeof(struct mach_header));
}

void macho_get_load_command(const void* macho_ptr, struct load_command* load_command_ptr) {
    memcpy(load_command_ptr, macho_ptr, sizeof(struct load_command));
}

uint32_t is_fat(const void* ptr) {
    const struct fat_header* header = ptr;
    return header->magic == FAT_MAGIC || header->magic == FAT_CIGAM;
}
