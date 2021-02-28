//
//  ContentView.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import SwiftUI

struct ContentView: View {
    @State var machoList: [MachO] = []

    init() {
        let url = URL(fileURLWithPath: "/bin/ls")
        do {
            let fatMacho = try FatMachO.fromURL(url)
            self._machoList = State(initialValue: fatMacho.machoList)
        } catch {
            print(error)
        }
    }

    var body: some View {
        List {
            ForEach(self.machoList) { macho in
                Section(header: Text(String(describing: macho.cpu)), content: {
                    ForEach(macho.cmds) { lc in
                        NavigationLink(
                            destination: LoadCommandView(lc: lc),
                            label: {
                                Text(String(describing: lc.cmd))
                            })
                    }
                })
                Divider()
            }
        }
    }
}

struct LoadCommandView: View {
    let lc: LoadCommand

    var body: some View {
        VStack {
            Text(String(describing: lc.cmd))
            Text(String(describing: lc.cmdsize) + " bytes")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
