//
//  RestoreBackupView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct RestoreBackupView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var exerciseStore: ExerciseStore

    @ObservedObject var backupStore: BackupFileStore

    @State private var restoreResult: Result<Void, Error>?
    @State private var restoreBackupUrl: URL?

    private var alertTitle: String {
        guard let result = restoreResult else { return "" }
        switch result {
        case .success:
            return "復元成功"
        case .failure:
            return "復元失敗"
        }
    }

    private var alertMessage: String {
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
        List {
            Section(header: Text("バックアップ".uppercased()), footer: Text("タップして復元します")) {
                ForEach(backupStore.backups) { backup in
                    Button(action: {
                        self.restoreBackupUrl = backup.url
                    }) {
                        VStack(alignment: .leading) {
                            Text(BackupFileStore.BackupFile.dateFormatter.string(from: backup.creationDate))
                                .foregroundColor(.primary)
                            Text("\(backup.deviceName) • \(BackupFileStore.BackupFile.byteCountFormatter.string(fromByteCount: Int64(backup.fileSize)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        self.backupStore.delete(at: index)
                    }
                }

                // TODO: remove this once the .placeholder() works
                if backupStore.backups.isEmpty {
                    Button("空") {}
                        .disabled(true)
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .onAppear(perform: backupStore.fetchBackups)
        .navigationBarItems(trailing: EditButton())
        .confirmationDialog("バックアップ復元", isPresented: Binding(
            get: { restoreBackupUrl != nil },
            set: { if !$0 { restoreBackupUrl = nil } }
        ), titleVisibility: .visible) {
            Button("復元", role: .destructive) {
                guard let url = restoreBackupUrl else { return }
                do {
                    let data = try Data(contentsOf: url)
                    try IronBackup.restoreBackupData(data: data, managedObjectContext: managedObjectContext, exerciseStore: exerciseStore)
                    restoreResult = .success(())
                } catch {
                    restoreResult = .failure(error)
                }
            }
            Button("キャンセル", role: .cancel) {
                restoreBackupUrl = nil
            }
        } message: {
            Text("この操作は取り消せません。すべてのワークアウトとカスタム種目がバックアップの内容に置き換わります。設定は影響を受けません。")
        }
        .alert(alertTitle, isPresented: Binding(
            get: { restoreResult != nil },
            set: { if !$0 { restoreResult = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if !alertMessage.isEmpty {
                Text(alertMessage)
            }
        }
        .navigationBarTitle("バックアップ復元", displayMode: .inline)
    }
}
