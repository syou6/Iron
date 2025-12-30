//
//  GeneralSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 31.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var weightPickerSection: some View {
        Section {
            Picker("重量単位", selection: $settingsStore.weightUnit) {
                ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                    Text(weightUnit.title).tag(weightUnit)
                }
            }
        }
    }

    private var restTimerTimesSection: some View {
        Section {
            Picker("デフォルト休憩時間", selection: $settingsStore.defaultRestTime) {
                ForEach(restTimerCustomTimes, id: \.self) { time in
                    Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                }
            }

            Picker("休憩時間（ダンベル）", selection: $settingsStore.defaultRestTimeDumbbellBased) {
                ForEach(restTimerCustomTimes, id: \.self) { time in
                    Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                }
            }

            Picker("休憩時間（バーベル）", selection: $settingsStore.defaultRestTimeBarbellBased) {
                ForEach(restTimerCustomTimes, id: \.self) { time in
                    Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                }
            }
        }
    }

    private var restTimerSection: some View {
        Section(footer: Text("タイマー終了後も継続します。超過時間は赤で表示されます。")) {
            Toggle("セット完了時に自動開始", isOn: $settingsStore.autoStartRestTimer)
            Toggle("タイマーを継続", isOn: Binding(get: {
                settingsStore.keepRestTimerRunning
            }, set: { newValue in
                settingsStore.keepRestTimerRunning = newValue

                // TODO in future somehow let RestTimerStore subscribe to this specific change
                RestTimerStore.shared.notifyKeepRestTimerRunningChanged()
            }))
        }
    }

    private var oneRmSection: some View {
        Section(footer: Text("1RM計算に使用する最大レップ数。値が大きいほど精度は下がります。")) {
            Picker("1RMの最大レップ数", selection: $settingsStore.maxRepetitionsOneRepMax) {
                ForEach(maxRepetitionsOneRepMaxValues, id: \.self) { i in
                    Text("\(i)").tag(i)
                }
            }
        }
    }

    private var defaultValuesSection: some View {
        Section(header: Text("デフォルト値"), footer: Text("新しいセットを追加する際のデフォルト値を設定します。")) {
            Picker("デフォルト重量", selection: $settingsStore.defaultWeight) {
                ForEach(defaultWeightValues, id: \.self) { weight in
                    Text("\(Int(weight)) \(settingsStore.weightUnit.unit.symbol)").tag(weight)
                }
            }

            Picker("デフォルトレップ数", selection: $settingsStore.defaultRepetitions) {
                ForEach(defaultRepetitionsValues, id: \.self) { reps in
                    Text("\(reps) 回").tag(reps)
                }
            }
        }
    }

    private var autoFillSection: some View {
        Section(footer: Text("オンにすると、新しいセットに前回のワークアウト記録を自動入力します。")) {
            Toggle("前回記録を自動入力", isOn: $settingsStore.autoFillLastRecord)
        }
    }

    var body: some View {
        Form {
            weightPickerSection
            defaultValuesSection
            autoFillSection
            restTimerTimesSection
            restTimerSection
            oneRmSection
        }
        .navigationBarTitle("一般", displayMode: .inline)
    }
}

#if DEBUG
struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
