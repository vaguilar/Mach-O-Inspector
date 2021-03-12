//
//  Parse.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 3/12/21.
//

import Foundation

struct DyLib {
    let rawPointer: UnsafeRawPointer
    let stringOffset: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> DyLib {
        var pointer = constPointer
        let stringOffset = pointer.load(as: UInt32.self)
        pointer += 4
        return DyLib(
            rawPointer: constPointer,
            stringOffset: stringOffset
        )
    }
}

struct LoadDyLibLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let dylib: DyLib

    static func parse(_ constPointer: UnsafeRawPointer) -> LoadDyLibLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let dylib = DyLib.parse(pointer)
        pointer += 4
        return LoadDyLibLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            dylib: dylib
        )
    }
}

struct UUIDLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let uuid: UUID

    static func parse(_ constPointer: UnsafeRawPointer) -> UUIDLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let uuid = UUID(uuid: (pointer).assumingMemoryBound(to: uuid_t.self).pointee)
        pointer += 16
        return UUIDLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            uuid: uuid
        )
    }
}

struct DyLdInfoLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let rebaseOffset: UInt32
    let rebaseSize: UInt32
    let bindOffset: UInt32
    let bindSize: UInt32
    let weakBindOffset: UInt32
    let weakBindSize: UInt32
    let lazyBindOffset: UInt32
    let lazyBindSize: UInt32
    let exportOffset: UInt32
    let exportSize: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> DyLdInfoLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let rebaseOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let rebaseSize = pointer.load(as: UInt32.self)
        pointer += 4
        let bindOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let bindSize = pointer.load(as: UInt32.self)
        pointer += 4
        let weakBindOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let weakBindSize = pointer.load(as: UInt32.self)
        pointer += 4
        let lazyBindOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let lazyBindSize = pointer.load(as: UInt32.self)
        pointer += 4
        let exportOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let exportSize = pointer.load(as: UInt32.self)
        pointer += 4
        return DyLdInfoLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            rebaseOffset: rebaseOffset,
            rebaseSize: rebaseSize,
            bindOffset: bindOffset,
            bindSize: bindSize,
            weakBindOffset: weakBindOffset,
            weakBindSize: weakBindSize,
            lazyBindOffset: lazyBindOffset,
            lazyBindSize: lazyBindSize,
            exportOffset: exportOffset,
            exportSize: exportSize
        )
    }
}

struct LoadDyLinkerLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let stringOffset: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> LoadDyLinkerLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let stringOffset = pointer.load(as: UInt32.self)
        pointer += 4
        return LoadDyLinkerLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            stringOffset: stringOffset
        )
    }
}

struct EntryPointLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let entryOffset: UInt64
    let stackSize: UInt64

    static func parse(_ constPointer: UnsafeRawPointer) -> EntryPointLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let entryOffset = pointer.load(as: UInt64.self)
        pointer += 8
        let stackSize = pointer.load(as: UInt64.self)
        pointer += 8
        return EntryPointLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            entryOffset: entryOffset,
            stackSize: stackSize
        )
    }
}

struct SegmentLoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let segmentName: String
    let vmAddress: UInt32
    let vmSize: UInt32
    let fileOffset: UInt32
    let fileSize: UInt32
    let maxProtection: UInt32
    let initialProtection: UInt32
    let sectionsCount: UInt32
    let flags: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> SegmentLoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let segmentNameBytes = UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: UInt8.self), count: 16)
        let segmentName = String(bytes: segmentNameBytes, encoding: .utf8)!
        pointer += 16
        let vmAddress = pointer.load(as: UInt32.self)
        pointer += 4
        let vmSize = pointer.load(as: UInt32.self)
        pointer += 4
        let fileOffset = pointer.load(as: UInt32.self)
        pointer += 4
        let fileSize = pointer.load(as: UInt32.self)
        pointer += 4
        let maxProtection = pointer.load(as: UInt32.self)
        pointer += 4
        let initialProtection = pointer.load(as: UInt32.self)
        pointer += 4
        let sectionsCount = pointer.load(as: UInt32.self)
        pointer += 4
        let flags = pointer.load(as: UInt32.self)
        pointer += 4
        return SegmentLoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            segmentName: segmentName,
            vmAddress: vmAddress,
            vmSize: vmSize,
            fileOffset: fileOffset,
            fileSize: fileSize,
            maxProtection: maxProtection,
            initialProtection: initialProtection,
            sectionsCount: sectionsCount,
            flags: flags
        )
    }
}

struct Segment64LoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32
    let segmentName: String
    let vmAddress: UInt64
    let vmSize: UInt64
    let fileOffset: UInt64
    let fileSize: UInt64
    let maxProtection: UInt32
    let initialProtection: UInt32
    let sectionsCount: UInt32
    let flags: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> Segment64LoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let segmentNameBytes = UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: UInt8.self), count: 16)
        let segmentName = String(bytes: segmentNameBytes, encoding: .utf8)!
        pointer += 16
        let vmAddress = pointer.load(as: UInt64.self)
        pointer += 8
        let vmSize = pointer.load(as: UInt64.self)
        pointer += 8
        let fileOffset = pointer.load(as: UInt64.self)
        pointer += 8
        let fileSize = pointer.load(as: UInt64.self)
        pointer += 8
        let maxProtection = pointer.load(as: UInt32.self)
        pointer += 4
        let initialProtection = pointer.load(as: UInt32.self)
        pointer += 4
        let sectionsCount = pointer.load(as: UInt32.self)
        pointer += 4
        let flags = pointer.load(as: UInt32.self)
        pointer += 4
        return Segment64LoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size,
            segmentName: segmentName,
            vmAddress: vmAddress,
            vmSize: vmSize,
            fileOffset: fileOffset,
            fileSize: fileSize,
            maxProtection: maxProtection,
            initialProtection: initialProtection,
            sectionsCount: sectionsCount,
            flags: flags
        )
    }
}

struct LoadCommand {
    let rawPointer: UnsafeRawPointer
    let command: UInt32
    let size: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> LoadCommand {
        var pointer = constPointer
        let command = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        return LoadCommand(
            rawPointer: constPointer,
            command: command,
            size: size
        )
    }
}

struct MachHeader {
    let rawPointer: UnsafeRawPointer
    let magic: UInt32
    let cpuType: Int32
    let cpuSubtype: Int32
    let fileType: UInt32
    let commandsCount: UInt32
    let commandsSize: UInt32
    let flags: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> MachHeader {
        var pointer = constPointer
        let magic = pointer.load(as: UInt32.self)
        pointer += 4
        let cpuType = pointer.load(as: Int32.self)
        pointer += 4
        let cpuSubtype = pointer.load(as: Int32.self)
        pointer += 4
        let fileType = pointer.load(as: UInt32.self)
        pointer += 4
        let commandsCount = pointer.load(as: UInt32.self)
        pointer += 4
        let commandsSize = pointer.load(as: UInt32.self)
        pointer += 4
        let flags = pointer.load(as: UInt32.self)
        pointer += 4
        return MachHeader(
            rawPointer: constPointer,
            magic: magic,
            cpuType: cpuType,
            cpuSubtype: cpuSubtype,
            fileType: fileType,
            commandsCount: commandsCount,
            commandsSize: commandsSize,
            flags: flags
        )
    }
}

struct MachHeader64 {
    let rawPointer: UnsafeRawPointer
    let magic: UInt32
    let cpuType: Int32
    let cpuSubtype: Int32
    let fileType: UInt32
    let commandsCount: UInt32
    let commandsSize: UInt32
    let flags: UInt32
    let reserved: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> MachHeader64 {
        var pointer = constPointer
        let magic = pointer.load(as: UInt32.self)
        pointer += 4
        let cpuType = pointer.load(as: Int32.self)
        pointer += 4
        let cpuSubtype = pointer.load(as: Int32.self)
        pointer += 4
        let fileType = pointer.load(as: UInt32.self)
        pointer += 4
        let commandsCount = pointer.load(as: UInt32.self)
        pointer += 4
        let commandsSize = pointer.load(as: UInt32.self)
        pointer += 4
        let flags = pointer.load(as: UInt32.self)
        pointer += 4
        let reserved = pointer.load(as: UInt32.self)
        pointer += 4
        return MachHeader64(
            rawPointer: constPointer,
            magic: magic,
            cpuType: cpuType,
            cpuSubtype: cpuSubtype,
            fileType: fileType,
            commandsCount: commandsCount,
            commandsSize: commandsSize,
            flags: flags,
            reserved: reserved
        )
    }
}

struct FatArch {
    let rawPointer: UnsafeRawPointer
    let cpuType: Int32
    let cpuSubtype: Int32
    let offset: UInt32
    let size: UInt32
    let align: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> FatArch {
        var pointer = constPointer
        let cpuType = pointer.load(as: Int32.self)
        pointer += 4
        let cpuSubtype = pointer.load(as: Int32.self)
        pointer += 4
        let offset = pointer.load(as: UInt32.self)
        pointer += 4
        let size = pointer.load(as: UInt32.self)
        pointer += 4
        let align = pointer.load(as: UInt32.self)
        pointer += 4
        return FatArch(
            rawPointer: constPointer,
            cpuType: cpuType,
            cpuSubtype: cpuSubtype,
            offset: offset,
            size: size,
            align: align
        )
    }
}

struct FatHeader {
    let rawPointer: UnsafeRawPointer
    let magic: UInt32
    let archCount: UInt32

    static func parse(_ constPointer: UnsafeRawPointer) -> FatHeader {
        var pointer = constPointer
        let magic = pointer.load(as: UInt32.self)
        pointer += 4
        let archCount = pointer.load(as: UInt32.self)
        pointer += 4
        return FatHeader(
            rawPointer: constPointer,
            magic: magic,
            archCount: archCount
        )
    }
}
