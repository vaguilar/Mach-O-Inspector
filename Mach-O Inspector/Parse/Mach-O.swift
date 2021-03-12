//
//  Mach-O.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import Foundation

class FatMachO {
    let machoList: [MachO]

    init(_ machoList: [MachO]) {
        self.machoList = machoList
    }

    static func fromPointer(_ fatMachOPointer: UnsafeRawPointer) throws -> FatMachO {
        var machoList: [MachO] = []
        let isFat = is_fat(fatMachOPointer) == 1

        if isFat {
            let fatHeader = FatHeader.parse(fatMachOPointer)

            for i in 0..<Int(fatHeader.archCount) {
                let fatArchPointer = fatMachOPointer + MemoryLayout<FatHeader>.stride + (MemoryLayout<FatArch>.stride * i)
                let fatArch = FatArch.parse(fatArchPointer)
                let machoPointer = fatMachOPointer + Int(fatArch.offset)
                let machO = try MachO.fromPointer(machoPointer)
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
    let loadCommands: [LoadCommand]
    let flags: UInt32
    let displayLists: [[(String, String)]]

    init(cpu: CPUType, cpusub: CPUSubType, filetype: FileType, loadCommands: [LoadCommand], flags: UInt32, displayLists: [[(String, String)]]) {
        self.cpu = cpu
        self.cpusub = cpusub
        self.filetype = filetype
        self.loadCommands = loadCommands
        self.flags = flags
        self.displayLists = displayLists
    }

    static func fromPointer(_ machOPointer: UnsafeRawPointer) throws -> MachO {
        let machHeader = MachHeader.parse(machOPointer)
        var loadCommandPointer = machOPointer + 32
        var loadCommands: [LoadCommand] = []
        var displayLists: [[(String, String)]] = []

        // is 64-bit?
        if machHeader.cpuType & CPUType.CPU_TYPE_64.rawValue != 0 {
            loadCommandPointer = machOPointer + 32
        }

        for _ in 0..<machHeader.commandsCount {
            let loadCommand = LoadCommand.parse(loadCommandPointer)
            loadCommands.append(loadCommand)
            displayLists.append(loadCommand.toDisplayList())
            loadCommandPointer += Int(loadCommand.size)
        }

        guard let cpu = CPUType(rawValue: machHeader.cpuType) else {
            throw MachOParseError.unknownCPU(value: machHeader.cpuType)
        }

        guard let cpusub = CPUSubType(rawValue: machHeader.cpuSubtype & ~CPUSubType.CPU_SUBTYPE_MASK.rawValue) else {
            throw MachOParseError.unknownCPUSub(value: machHeader.cpuSubtype)
        }

        guard let filetype = FileType(rawValue: machHeader.fileType) else {
            throw MachOParseError.unknownFileType(value: machHeader.fileType)
        }

        return MachO(cpu: cpu, cpusub: cpusub, filetype: filetype, loadCommands: loadCommands, flags: machHeader.flags, displayLists: displayLists)
    }

    static func fromURL(_ url: URL) throws -> MachO {
        guard let data = try? Data(contentsOf: url) else {
            throw MachOParseError.unableToOpenFile
        }

        return try data.withUnsafeBytes { try MachO.fromPointer($0.baseAddress!) }
    }

    static func == (lhs: MachO, rhs: MachO) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension LoadCommand {
    func toDisplayList() -> [(String, String)] {
        let loadCommand = LoadCommandType(rawValue: self.command)
        var result: [(String, String)] = [
            ("Command", (loadCommand != nil) ? String(describing: loadCommand!) : "???"),
            ("Size", String(self.size)),
        ]
        switch loadCommand {
        case .LC_SEGMENT_64:
            let lc = Segment64LoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("Segment Name", lc.segmentName),
                ("File Offset", String(format: "0x%X", lc.fileOffset)),
                ("File Size", String(format: "0x%X", lc.fileSize)),
                ("VM Address", String(format: "0x%X", lc.vmAddress)),
                ("VM Size", String(format: "0x%X", lc.vmSize)),
            ])
        case .LC_DYLD_INFO, .LC_DYLD_INFO_ONLY:
            let lc = DyLdInfoLoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("Rebase Offset", String(format: "0x%X", lc.rebaseOffset)),
                ("Rebase Size", String(format: "0x%X", lc.rebaseSize)),
                ("Bind Offset", String(format: "0x%X", lc.bindOffset)),
                ("Bind Size", String(format: "0x%X", lc.bindSize)),
                ("Lazy Bind Offset", String(format: "0x%X", lc.lazyBindOffset)),
                ("Lazy Bind Size", String(format: "0x%X", lc.lazyBindSize)),
                ("Weak Bind Offset", String(format: "0x%X", lc.weakBindOffset)),
                ("Weak Bind Size", String(format: "0x%X", lc.weakBindSize)),
                ("Export Offset", String(format: "0x%X", lc.exportOffset)),
                ("Export Size", String(format: "0x%X", lc.exportSize)),
            ])
        case .LC_UUID:
            let lc = UUIDLoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("UUID", lc.uuid.uuidString),
            ])
        case .LC_LOAD_DYLIB, .LC_LOAD_WEAK_DYLIB, .LC_RPATH:
            let lc = LoadDyLibLoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("Path", lc.pathString()),
            ])
        case .LC_LOAD_DYLINKER:
            let lc = LoadDyLinkerLoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("Path", lc.pathString()),
            ])
        case .LC_MAIN:
            let lc = EntryPointLoadCommand.parse(self.rawPointer)
            result.append(contentsOf: [
                ("Entry Offset", String(format: "0x%X", lc.entryOffset)),
                ("Stack Size", String(format: "0x%X", lc.stackSize)),
            ])
        default:
            // noop
            result.append(contentsOf: [])
        }

        return result
    }
}

extension LoadDyLibLoadCommand {
    func pathString() -> String {
        let pointer = UnsafePointer<UInt8>(self.rawPointer.assumingMemoryBound(to: UInt8.self) + Int(self.dylib.stringOffset))
        return String(cString: pointer)
    }
}

extension LoadDyLinkerLoadCommand {
    func pathString() -> String {
        let pointer = UnsafePointer<UInt8>(self.rawPointer.assumingMemoryBound(to: UInt8.self) + Int(self.stringOffset))
        return String(cString: pointer)
    }
}
