//
//  WorkoutPlanView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutPlanView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    
    @State private var offsetsToDelete: IndexSet?
    
    @State private var workoutPlanTitleInput: String? = nil
    private var workoutPlanTitle: Binding<String> {
        Binding(
            get: {
                self.workoutPlanTitleInput ?? self.workoutPlan.title ?? ""
            },
            set: { newValue in
                self.workoutPlanTitleInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutTitleInput() {
        guard let newValue = workoutPlanTitleInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutPlanTitleInput = newValue
        workoutPlan.title = newValue.isEmpty ? nil : newValue
        self.managedObjectContext.saveOrCrash()
    }
    
    private var workoutRoutines: [WorkoutRoutine] {
        workoutPlan.workoutRoutines?.array as? [WorkoutRoutine] ?? []
    }
    
    var body: some View {
        List {
            Section {
                TextField("タイトル", text: workoutPlanTitle, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutTitleInput()
                    }
                })
            }
            Section(header: Text("ルーティン".uppercased())) {
                ForEach(workoutRoutines) { workoutRoutine in
                    NavigationLink(destination: WorkoutRoutineView(workoutRoutine: workoutRoutine)) {
                        VStack(alignment: .leading) {
                            Text(workoutRoutine.displayTitle)
                            Text(workoutRoutine.subtitle(in: self.exerciseStore.exercises))
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            let copy = workoutRoutine.duplicate(context: self.managedObjectContext)
                            copy.workoutPlan = self.workoutPlan
                            self.managedObjectContext.saveOrCrash()
                        }) {
                            Label("複製", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive, action: {
                            self.managedObjectContext.delete(workoutRoutine)
                            self.managedObjectContext.saveOrCrash()
                        }) {
                            Label("削除", systemImage: "trash")
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
                .onMove { source, destination in
                    var workoutRoutines = self.workoutRoutines
                    workoutRoutines.move(fromOffsets: source, toOffset: destination)
                    self.workoutPlan.workoutRoutines = NSOrderedSet(array: workoutRoutines)
                    self.managedObjectContext.saveOrCrash()
                }
                
                Button(action: {
                    self.createWorkoutRoutine()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("ルーティンを追加")
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationBarTitle(Text(workoutPlan.displayTitle), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .confirmationDialog("この操作は取り消せません", isPresented: Binding(
            get: { offsetsToDelete != nil },
            set: { if !$0 { offsetsToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("ルーティンを削除", role: .destructive) {
                if let offsets = offsetsToDelete {
                    self.deleteAt(offsets: offsets)
                }
            }
            Button("キャンセル", role: .cancel) {
                offsetsToDelete = nil
            }
        }
    }
    
    private func createWorkoutRoutine() {
        let workoutRoutine = WorkoutRoutine.create(context: managedObjectContext)
        workoutRoutine.workoutPlan = workoutPlan
        managedObjectContext.saveOrCrash()
    }
    
    /// Resturns `true` if at least one workout routine has workout routine exercises
    private func needsConfirmBeforeDelete(offsets: IndexSet) -> Bool {
        for index in offsets {
            if workoutRoutines[index].workoutRoutineExercises?.count ?? 0 != 0 {
                return true
            }
        }
        return false
    }
    
    private func deleteAt(offsets: IndexSet) {
        let workoutRoutines = self.workoutRoutines
        for i in offsets {
            self.managedObjectContext.delete(workoutRoutines[i])
        }
        self.managedObjectContext.saveOrCrash()
    }
}

#if DEBUG
struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutPlanView(workoutPlan: MockWorkoutData.metric.workoutPlan)
                .mockEnvironment(weightUnit: .metric)
        }
    }
}
#endif
