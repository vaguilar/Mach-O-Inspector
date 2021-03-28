//
//  ContentView.swift
//  Mach-O Inspector
//
//  Created by Victor Aguilar on 2/27/21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var env: MachOInspectorEnvironment

    var body: some View {
        List {
            ForEach(self.env.machoList) { macho in
                Section(header: Text(String(describing: macho.cpu)), content: {
                    ForEach(0..<macho.loadCommands.count) { i in
                        NavigationLink(
                            destination: LoadCommandView(loadCommand: macho.loadCommands[i], displayList: macho.displayLists[i]),
                            label: {
                                Text(String(describing: LoadCommandType(rawValue: macho.loadCommands[i].command)!))
                            })
                    }
                })
                Divider()
            }
        }
    }
}

struct LoadCommandView: View {
    let loadCommand: LoadCommand
    let displayList: [(String, String)]

    var body: some View {
        HStack {
            VStack {
                Text("")
                ForEach(0..<displayList.count) { i in
                    Text(displayList[i].0)
                        .bold()
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                }
            }
            VStack {
                Text("")
                ForEach(0..<displayList.count) { i in
                    Text(displayList[i].1)
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
