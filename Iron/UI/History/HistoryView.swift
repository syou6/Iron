//
//  HistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct HistoryView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var sceneState: SceneState
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(fetchRequest: HistoryView.fetchRequest) var workouts

    static var fetchRequest: NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }
    
    @State private var activityItems: [Any]?
    
    @State private var offsetsToDelete: IndexSet?
    
    /// Resturns `true` if at least one workout has workout exercises
    private func needsConfirmBeforeDelete(offsets: IndexSet) -> Bool {
        for index in offsets {
            if workouts[index].workoutExercises?.count ?? 0 != 0 {
                return true
            }
        }
        return false
    }
    
    private func deleteAt(offsets: IndexSet) {
        let workouts = self.workouts
        for i in offsets.sorted().reversed() {
            workouts[i].deleteOrCrash()
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)
                        .environmentObject(self.settingsStore)
                    ) {
                        WorkoutCell(workout: workout)
                            .contextMenu {
                                // TODO add images when SwiftUI fixes the image size
                                if UIDevice.current.userInterfaceIdiom != .pad {
                                    // not working on iPad, last checked iOS 13.4
                                    Button("共有") {
                                        guard let logText = workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                                        self.activityItems = [logText]
                                    }
                                }
                                Button("繰り返し") {
                                    WorkoutDetailView.repeatWorkout(workout: workout, settingsStore: self.settingsStore, sceneState: sceneState)
                                }
                                Button("繰り返し（空白）") {
                                    WorkoutDetailView.repeatWorkoutBlank(workout: workout, settingsStore: self.settingsStore, sceneState: sceneState)
                                }
                        }
                    }
                }
                .onDelete { offsets in
                    if self.needsConfirmBeforeDelete(offsets: offsets) {
                        self.offsetsToDelete = offsets
                    } else {
                        self.deleteAt(offsets: offsets)
                    }
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .navigationBarItems(trailing: EditButton())
            .confirmationDialog("この操作は取り消せません", isPresented: Binding(
                get: { offsetsToDelete != nil },
                set: { if !$0 { offsetsToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("ワークアウトを削除", role: .destructive) {
                    if let offsets = offsetsToDelete {
                        self.deleteAt(offsets: offsets)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    offsetsToDelete = nil
                }
            }
            // FIXME: .placeholder() suddenly crashes the app when the last workout is deleted (iOS 13.4)
            .placeholder(show: workouts.isEmpty,
                         Text("完了したワークアウトがここに表示されます")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
            )
            .navigationBarTitle(Text("履歴"))
        }
        .overlay(ActivitySheet(activityItems: self.$activityItems))
    }
}

private struct WorkoutCell: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject var workout: Workout

    private var durationString: String? {
        guard let duration = workout.duration else { return nil }
        return Workout.durationFormatter.string(from: duration)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(workout.displayTitle(in: self.exerciseStore.exercises))
                    .font(.body)
                
                Text(Workout.dateFormatter.string(from: workout.start, fallback: "日付不明"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                workout.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer()
            
            durationString.map {
                Text($0)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(Color(.systemFill))
                    )
            }
            
            workout.muscleGroupImage(in: self.exerciseStore.exercises)
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
