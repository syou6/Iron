//
//  SessionContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

let NAVIGATION_BAR_SPACING: CGFloat = 16

struct ContentView : View {
    @EnvironmentObject private var sceneState: SceneState

    @State private var restoreResult: Result<Void, Error>?
    @State private var restoreBackupData: Data?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var restoreAlertTitle: String {
        guard let result = restoreResult else { return "" }
        switch result {
        case .success:
            return "復元成功"
        case .failure:
            return "復元失敗"
        }
    }

    private var restoreAlertMessage: String {
        guard let result = restoreResult else { return "" }
        switch result {
        case .success:
            return ""
        case .failure(let error):
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .dataCorrupted(context):
                    return "データ破損: \(context.debugDescription)"
                case let .keyNotFound(_, context):
                    return "キーが見つかりません: \(context.debugDescription)"
                case let .typeMismatch(_, context):
                    return "型の不一致: \(context.debugDescription)"
                case let .valueNotFound(_, context):
                    return "値が見つかりません: \(context.debugDescription)"
                @unknown default:
                    return "デコードエラー: \(error.localizedDescription)"
                }
            } else {
                return error.localizedDescription
            }
        }
    }

    var body: some View {
        ZStack {
            tabView
            .edgesIgnoringSafeArea([.top, .bottom])
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.RestoreFromBackup)) { output in
                guard let backupData = output.userInfo?[restoreFromBackupDataUserInfoKey] as? Data else { return }
                self.restoreBackupData = backupData
            }
            .confirmationDialog("バックアップ復元", isPresented: Binding(
                get: { restoreBackupData != nil },
                set: { if !$0 { restoreBackupData = nil } }
            ), titleVisibility: .visible) {
                Button("復元", role: .destructive) {
                    guard let data = restoreBackupData else { return }
                    do {
                        try IronBackup.restoreBackupData(data: data, managedObjectContext: WorkoutDataStorage.shared.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared)
                        restoreResult = .success(())
                    } catch {
                        restoreResult = .failure(error)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    restoreBackupData = nil
                }
            } message: {
                Text("この操作は取り消せません。すべてのワークアウトとカスタム種目がバックアップの内容に置き換わります。設定は影響を受けません。")
            }
            .alert(restoreAlertTitle, isPresented: Binding(
                get: { restoreResult != nil },
                set: { if !$0 { restoreResult = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if !restoreAlertMessage.isEmpty {
                    Text(restoreAlertMessage)
                }
            }

            if !hasSeenOnboarding {
                OnboardingView(showOnboarding: Binding(
                    get: { !self.hasSeenOnboarding },
                    set: { if !$0 { self.hasSeenOnboarding = true } }
                ))
                .transition(.opacity)
            }
        }
    }
    
    private var tabView: some View {
        TabView(selection: $sceneState.selectedTabNumber) {
            FeedView()
                .tag(SceneState.Tab.feed.rawValue)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            HistoryView()
                .tag(SceneState.Tab.history.rawValue)
                .tabItem {
                    Label("履歴", systemImage: "clock")
                }

            WorkoutTab()
                .tag(SceneState.Tab.workout.rawValue)
                .tabItem {
                    Label("ワークアウト", systemImage: "plus.diamond")
                }

            ExerciseMuscleGroupsView()
                .tag(SceneState.Tab.exercises.rawValue)
                .tabItem {
                    Label("種目", systemImage: "tray.full")
                }

            SettingsView()
                .tag(SceneState.Tab.settings.rawValue)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
        .productionEnvironment()
    }
}

private extension View {
    func productionEnvironment() -> some View {
        self
            .environmentObject(SettingsStore.shared)
            .environmentObject(RestTimerStore.shared)
            .environmentObject(ExerciseStore.shared)
            .environment(\.managedObjectContext, WorkoutDataStorage.shared.persistentContainer.viewContext)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
