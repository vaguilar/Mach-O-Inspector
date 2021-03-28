//
//  Mach_O_InspectorApp.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import SwiftUI

class MachOInspectorEnvironment: ObservableObject {
    @Published var machoList: [MachO] = []

    init() {
        let url = Bundle.main.executableURL!
        do {
            let fatMacho = try FatMachO.fromURL(url)
            self._machoList = Published(initialValue: fatMacho.machoList)
        } catch {
            print(error)
        }
    }
}

@main
struct Mach_O_InspectorApp: App {
    @StateObject var env = MachOInspectorEnvironment()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(env)
            }
        }
    }
}
