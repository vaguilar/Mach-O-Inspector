//
//  Mach-O.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import Foundation

enum CPUType: Int32 {
    case CPU_TYPE_ANY = -1
    case CPU_TYPE_VAX = 1
    case CPU_TYPE_ROMP = 2
    case CPU_TYPE_NS32032 = 4
    case CPU_TYPE_NS32332 = 5
    case CPU_TYPE_MC680x0 = 6
    case CPU_TYPE_I386 = 7
    case CPU_TYPE_X86_64 = 16777223
    case CPU_TYPE_MIPS = 8
    case CPU_TYPE_NS32532 = 9
    case CPU_TYPE_HPPA = 11
    case CPU_TYPE_ARM = 12
    case CPU_TYPE_MC88000 = 13
    case CPU_TYPE_SPARC = 14
    case CPU_TYPE_I860 = 15
    case CPU_TYPE_I860_LITTLE = 16
    case CPU_TYPE_RS6000 = 17
    case CPU_TYPE_POWERPC = 18
    case CPU_TYPE_POWERPC64 = 16777232
    case CPU_TYPE_VEO = 255
    case CPU_TYPE_ARM64 = 16777228
}

enum CPUSubType: Int32 {
    case CPU_SUBTYPE_ARM64_ALL = 0
    case CPU_SUBTYPE_ARM64_V8 = 1
    case CPU_SUBTYPE_ARM64E = 2
    case CPU_SUBTYPE_X86_ALL = 3
    case CPU_SUBTYPE_X86_ARCH1 = 4
    case CPU_SUBTYPE_ARM_V7 = 9
    case CPU_SUBTYPE_ARM_V7S = 11
    case CPU_SUBTYPE_ARM_V7K = 12

    case CPU_SUBTYPE_MASK = -2147483648
}

enum FileType: UInt32 {
    case MH_OBJECT = 1
    case MH_EXECUTE = 2
    case MH_FVMLIB = 3
    case MH_CORE = 4
    case MH_PRELOAD = 5
    case MH_DYLIB = 6
    case MH_DYLINKER = 7
    case MH_BUNDLE = 8
}

enum LoadCommandType: UInt32 {
    case LC_SEGMENT = 0x1
    case LC_SYMTAB = 0x2
    case LC_SYMSEG = 0x3
    case LC_THREAD = 0x4
    case LC_UNIXTHREAD = 0x5
    case LC_LOADFVMLIB = 0x6
    case LC_IDFVMLIB = 0x7
    case LC_IDENT = 0x8
    case LC_FVMFILE = 0x9
    case LC_PREPAGE = 0xa
    case LC_DYSYMTAB = 0xb
    case LC_LOAD_DYLIB = 0xc
    case LC_ID_DYLIB = 0xd
    case LC_LOAD_DYLINKER = 0xe
    case LC_ID_DYLINKER = 0xf
    case LC_PREBOUND_DYLIB = 0x10
    case LC_ROUTINES = 0x11
    case LC_SUB_FRAMEWORK = 0x12
    case LC_SUB_UMBRELLA = 0x13
    case LC_SUB_CLIENT = 0x14
    case LC_SUB_LIBRARY = 0x15
    case LC_TWOLEVEL_HINTS = 0x16
    case LC_PREBIND_CKSUM = 0x17
    case LC_LOAD_WEAK_DYLIB = 0x80000018
    case LC_SEGMENT_64 = 0x19
    case LC_ROUTINES_64 = 0x1a
    case LC_UUID = 0x1b
    case LC_RPATH = 0x8000001c
    case LC_CODE_SIGNATURE = 0x1d
    case LC_SEGMENT_SPLIT_INFO = 0x1e
    case LC_REEXPORT_DYLIB = 0x8000001f
    case LC_LAZY_LOAD_DYLIB = 0x20
    case LC_ENCRYPTION_INFO = 0x21
    case LC_DYLD_INFO = 0x22
    case LC_DYLD_INFO_ONLY = 0x80000022
    case LC_LOAD_UPWARD_DYLIB = 0x80000023
    case LC_VERSION_MIN_MACOSX = 0x80000024
    case LC_VERSION_MIN_IPHONEOS = 0x25
    case LC_FUNCTION_STARTS = 0x26
    case LC_DYLD_ENVIRONMENT = 0x27
    case LC_MAIN = 0x80000028
    case LC_DATA_IN_CODE = 0x29
    case LC_SOURCE_VERSION = 0x2A
    case LC_DYLIB_CODE_SIGN_DRS = 0x2B
    case LC_ENCRYPTION_INFO_64 = 0x2C
    case LC_LINKER_OPTION = 0x2D
    case LC_LINKER_OPTIMIZATION_HINT = 0x2E
    case LC_VERSION_MIN_TVOS = 0x2F
    case LC_VERSION_MIN_WATCHOS = 0x30
    case LC_NOTE = 0x31
    case LC_BUILD_VERSION = 0x32
    case LC_DYLD_EXPORTS_TRIE = 0x80000033
    case LC_DYLD_CHAINED_FIXUPS = 0x80000034
}

enum MachOParseError: Error {
    case unableToOpenFile
    case unknownCPU(value: Int32)
    case unknownCPUSub(value: Int32)
    case unknownFileType(value: UInt32)
    case unknownLoadCommand(value: UInt32)
}

class FatMachO {
    let machoList: [MachO]

    init(_ machoList: [MachO]) {
        self.machoList = machoList
    }

    static func fromPointer(_ fatMachOPointer: UnsafeRawPointer) throws -> FatMachO {
        var machoList: [MachO] = []
        let isFat = is_fat(fatMachOPointer) == 1

        if isFat {
            var buffer = Data(capacity: 32)
            let fatHeader = buffer.withUnsafeMutableBytes { (fatHeaderRawPointer) -> fat_header in
                let fatHeaderPointer = fatHeaderRawPointer.bindMemory(to: fat_header.self).baseAddress
                macho_fat_header(fatMachOPointer, fatHeaderPointer)
                return fatHeaderPointer!.pointee
            }

            for i in 0..<fatHeader.nfat_arch {
                let fatArch = buffer.withUnsafeMutableBytes { (fatArchRawPointer) -> fat_arch in
                    let fatArchPointer = fatArchRawPointer.bindMemory(to: fat_arch.self).baseAddress
                    macho_get_fat_arch(fatMachOPointer, Int(i), fatArchPointer)
                    return fatArchPointer!.pointee
                }

                let machHeaderPointer = fatMachOPointer.advanced(by: Int(fatArch.offset))
                let machO = try MachO.fromPointer(machHeaderPointer)
                machoList.append(machO)
            }
        } else {
            let machO = try MachO.fromPointer(fatMachOPointer)
            machoList.append(machO)
        }

        return FatMachO(machoList)
    }

    static func fromURL(_ url: URL) throws -> FatMachO {
        guard let data = try? Data(contentsOf: url) else {
            throw MachOParseError.unableToOpenFile
        }

        return try data.withUnsafeBytes { try FatMachO.fromPointer($0.baseAddress!) }
    }
}

struct MachO: Hashable, Identifiable {
    let id = UUID()
    let cpu: CPUType
    let cpusub: CPUSubType
    let filetype: FileType
    let cmds: [LoadCommand]
    let flags: UInt32

    init(cpu: CPUType, cpusub: CPUSubType, filetype: FileType, cmds: [LoadCommand], flags: UInt32) {
        self.cpu = cpu
        self.cpusub = cpusub
        self.filetype = filetype
        self.cmds = cmds
        self.flags = flags
    }

    static func fromPointer(_ machOPointer: UnsafeRawPointer) throws -> MachO {
        var buffer = Data(capacity: 64)
        let machHeader = buffer.withUnsafeMutableBytes { (machHeaderRawPointer) -> mach_header in
            let machHeaderPointer = machHeaderRawPointer.bindMemory(to: mach_header.self).baseAddress
            macho_get_mach_header(machOPointer, machHeaderPointer)
            return machHeaderPointer!.pointee
        }

        var cmds: [LoadCommand] = []
        var cmdPointer = machOPointer.advanced(by: 32)
        for _ in 0..<machHeader.ncmds {
            let lc = try LoadCommand.fromPointer(cmdPointer)
            cmds.append(lc)
            cmdPointer = cmdPointer.advanced(by: Int(lc.cmdsize))
        }

        guard let cpu = CPUType(rawValue: machHeader.cputype) else {
            throw MachOParseError.unknownCPU(value: machHeader.cputype)
        }

        guard let cpusub = CPUSubType(rawValue: machHeader.cpusubtype & ~CPUSubType.CPU_SUBTYPE_MASK.rawValue) else {
            throw MachOParseError.unknownCPUSub(value: machHeader.cpusubtype)
        }

        guard let filetype = FileType(rawValue: machHeader.filetype) else {
            throw MachOParseError.unknownFileType(value: machHeader.filetype)
        }

        return MachO(cpu: cpu, cpusub: cpusub, filetype: filetype, cmds: cmds, flags: machHeader.flags)
    }
}

struct LoadCommand: Hashable, Identifiable {
    let id = UUID()
    let cmd: LoadCommandType
    let cmdsize: UInt32

    init(cmd: LoadCommandType, cmdsize: UInt32) {
        self.cmd = cmd
        self.cmdsize = cmdsize
    }

    static func fromPointer(_ cmdPointer: UnsafeRawPointer) throws -> LoadCommand {
        let cmdValue = cmdPointer.load(fromByteOffset: 0, as: UInt32.self)
        let cmdsize = cmdPointer.load(fromByteOffset: 4, as: UInt32.self)

        guard let cmd = LoadCommandType(rawValue: cmdValue) else {
            throw MachOParseError.unknownLoadCommand(value: cmdValue)
        }
        return LoadCommand(cmd: cmd, cmdsize: cmdsize)
    }
}
