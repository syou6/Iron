//
//  BackupAndExportView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit
import os.log

struct BackupAndExportView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @ObservedObject var backupStore = BackupFileStore.shared
    
    @State private var showExportWorkoutDataSheet = false
    
    @State private var backupError: Error?

    @State private var activityItems: [Any]?
    
    private var cloudBackupFooter: some View {
        var strings = [String]()
        if settingsStore.autoBackup {
            strings.append("アプリ終了時に自動でバックアップが作成されます。")
        }
        strings.append("バックアップはiCloud Driveに保存されます。各日の最新のバックアップのみ保持されます。ファイルアプリからもアクセスできます。")
        if let creationDate = backupStore.lastBackup?.creationDate {
            strings.append("最終バックアップ: " + BackupFileStore.BackupFile.dateFormatter.string(from: creationDate))
        }

        return Text(strings.joined(separator: "\n"))
    }
    
    var body: some View {
        Form {
            Section(header: Text("エクスポート".uppercased())) {
                Button("ワークアウトデータ") {
                    self.showExportWorkoutDataSheet = true
                }
                Button("バックアップ") {
                    do {
                        os_log("Creating backup data", log: .backup, type: .default)
                        let data = try IronBackup.createBackupData(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore)
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let url = try self.tempFile(data: data, name: "\(formatter.string(from: Date())).ironbackup")
                        
                        self.shareFile(url: url)
                    } catch {
                        os_log("Could not create backup: %@", log: .backup, type: .default, error.localizedDescription)
                        self.backupError = error
                    }
                }
            }
            
            Section(header: Text("iCloudバックアップ".uppercased()), footer: cloudBackupFooter) {
                NavigationLink(destination: RestoreBackupView(backupStore: backupStore)) {
                    Text("復元")
                }
                Toggle("自動バックアップ", isOn: $settingsStore.autoBackup)
                Button("今すぐバックアップ") {
                    self.backupStore.create(data: {
                        return try self.managedObjectContext.performAndWait { context in
                            os_log("Creating backup data", log: .backup, type: .default)
                            return try IronBackup.createBackupData(managedObjectContext: context, exerciseStore: self.exerciseStore)
                        }
                    }, onError: { error in
                        self.backupError = error
                    })
                }
            }
        }
        .onAppear(perform: backupStore.fetchBackups)
        .navigationBarTitle("バックアップ", displayMode: .inline)
        .confirmationDialog("ワークアウトデータ", isPresented: $showExportWorkoutDataSheet, titleVisibility: .visible) {
            Button("JSON") {
                guard let workouts = self.fetchWorkouts() else { return }

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
                encoder.dateEncodingStrategy = .iso8601
                if let exercisesKey = CodingUserInfoKey.exercisesKey {
                    encoder.userInfo[exercisesKey] = ExerciseStore.shared.exercises
                }

                guard let data = try? encoder.encode(workouts) else { return }
                guard let url = try? self.tempFile(data: data, name: "workout_data.json") else { return }
                self.shareFile(url: url)
            }
            Button("TXT") {
                guard let workouts = self.fetchWorkouts() else { return }

                let text = workouts.compactMap { $0.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) }.joined(separator: "\n\n\n\n\n")

                guard let data = text.data(using: .utf8) else { return }
                guard let url = try? self.tempFile(data: data, name: "workout_data.txt") else { return }
                self.shareFile(url: url)
            }
            Button("キャンセル", role: .cancel) { }
        }
        .alert("バックアップを作成できませんでした", isPresented: Binding(
            get: { backupError != nil },
            set: { if !$0 { backupError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = backupError {
                Text(error.localizedDescription)
            }
        }
        .overlay(ActivitySheet(activityItems: $activityItems))
    }
    
    private func fetchWorkouts() -> [Workout]? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return (try? self.managedObjectContext.fetch(request))
    }
    
    private func tempFile(data: Data, name: String) throws -> URL {
        let path = FileManager.default.temporaryDirectory
        let url = path.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
    
    private func shareFile(url: URL) {
        self.activityItems = [url]
    }
}

#if DEBUG
struct BackupAndExportView_Previews: PreviewProvider {
    static var previews: some View {
        BackupAndExportView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
