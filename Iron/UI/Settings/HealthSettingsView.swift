//
//  HealthSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 31.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct HealthSettingsView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext

    @State private var updating = false
    @State private var updateResult: Result<HealthManager.WorkoutUpdates, Error>?

    private var alertTitle: String {
        guard let result = updateResult else { return "" }
        switch result {
        case .success:
            return "Apple Healthのワークアウトを更新しました"
        case .failure:
            return "Apple Healthの更新に失敗しました"
        }
    }

    private var alertMessage: String {
        guard let result = updateResult else { return "" }
        switch result {
        case .success(let updates):
            return "\(updates.created)件を作成、\(updates.deleted)件を削除、\(updates.modified)件を変更しました。"
        case .failure(let error):
            return error.localizedDescription
        }
    }

    var body: some View {
        Form {
            Section(footer: Text("不足しているワークアウトをApple Healthに追加し、削除されたワークアウトを削除します。開始・終了時刻が変更されたワークアウトも更新されます。")) {
                Button("Apple Healthワークアウトを更新") {
                    self.updating = true
                    HealthManager.shared.updateHealthWorkouts(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore) { result in
                        DispatchQueue.main.async {
                            self.updateResult = result
                            self.updating = false
                        }
                    }
                }
                .disabled(updating) // wait for updating to finish before allowing to tap again
            }
        }
        .navigationBarTitle("Apple Health", displayMode: .inline)
        .alert(alertTitle, isPresented: Binding(
            get: { updateResult != nil },
            set: { if !$0 { updateResult = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

import HealthKit
extension HealthSettingsView {
    static var isSupported: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
}

struct HealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthSettingsView()
    }
}
