//
//  WatchSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 12.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var footer: String {
        if settingsStore.watchCompanion {
            return "ワークアウトを開始すると、Apple Watchコンパニオンアプリが自動的に起動し、心拍数とカロリー消費を記録します。"
        } else {
            return "ワークアウトを開始しても、Apple Watchコンパニオンアプリは自動的に起動しません。"
        }
    }

    var body: some View {
        Form {
            Section(footer: Text(footer)) {
                Toggle(isOn: $settingsStore.watchCompanion) {
                    Text("Apple Watchコンパニオン")
                }
            }
        }
        .navigationBarTitle("Apple Watch", displayMode: .inline)
    }
}

import WatchConnectivity
extension WatchSettingsView {
    static var isSupported: Bool {
        WCSession.isSupported()
    }
}

struct WatchSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        WatchSettingsView().environmentObject(SettingsStore.shared)
    }
}
