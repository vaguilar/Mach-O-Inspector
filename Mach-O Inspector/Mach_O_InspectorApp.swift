//
//  Mach_O_InspectorApp.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import SwiftUI

class MachOInspectorEnvironment: ObservableObject {
    @Published var machoList: [MachO] = []
    @Published var title: String = ""

    init() {
        if let url = Bundle.main.executableURL {
            self.open(url)
        }
    }

    func open(_ url: URL) {
        do {
            let fatMacho = try FatMachO.fromURL(url)
            self.machoList = fatMacho.machoList
            self.title = url.lastPathComponent
        } catch {
            print(error)
        }
    }
}

@main
struct Mach_O_InspectorApp: App {
    @StateObject var env = MachOInspectorEnvironment()
    @State private var isFilePickerShown = false

    let openPanel = NSOpenPanel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(env)
            }
            .navigationTitle(self.env.title)
        }
        .commands {
            CommandGroup(after: CommandGroupPlacement.newItem) {
                Button(action: {
                    openPanel.begin { (result) in
                        if result == .OK, let url = openPanel.url {
                            self.env.open(url)
                        }
                    }
                }) {
                    Text("Open File...")
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
