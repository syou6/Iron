//
//  WorkoutRoutineView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutRoutineView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext

    @ObservedObject var workoutRoutine: WorkoutRoutine

    @State private var showExerciseSelector = false
    @State private var shareItems: [Any]?
    
    @State private var workoutRoutineTitleInput: String? = nil
    private var workoutRoutineTitle: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineTitleInput ?? self.workoutRoutine.title ?? ""
            },
            set: { newValue in
                self.workoutRoutineTitleInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineTitleInput() {
        guard let newValue = workoutRoutineTitleInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineTitleInput = newValue
        workoutRoutine.title = newValue.isEmpty ? nil : newValue
        self.managedObjectContext.saveOrCrash()
    }
    
    @State private var workoutRoutineCommentInput: String? = nil
    private var workoutRoutineComment: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineCommentInput ?? self.workoutRoutine.comment ?? ""
            },
            set: { newValue in
                self.workoutRoutineCommentInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineCommentInput() {
        guard let newValue = workoutRoutineCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineCommentInput = newValue
        workoutRoutine.comment = newValue.isEmpty ? nil : newValue
        self.managedObjectContext.saveOrCrash()
    }
    
    private var workoutRoutineExercises: [WorkoutRoutineExercise] {
        workoutRoutine.workoutRoutineExercises?.array as? [WorkoutRoutineExercise] ?? []
    }
    
    private var exerciseSelectorSheet: some View {
        AddExercisesSheet(
            exercises: exerciseStore.shownExercises,
            recentExercises: AddExercisesSheet.loadRecentExercises(context: managedObjectContext, exercises: exerciseStore.shownExercises),
            onAdd: { selection in
                for exercise in selection {
                    let workoutRoutineExercise = WorkoutRoutineExercise.create(context: self.managedObjectContext)
                    workoutRoutineExercise.workoutRoutine = self.workoutRoutine
                    workoutRoutineExercise.exerciseUuid = exercise.uuid
                    // TODO: add default sets?
                }
                self.managedObjectContext.saveOrCrash()
            }
        )
    }
    
    var body: some View {
        List {
            Section {
                TextField("タイトル", text: workoutRoutineTitle, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutRoutineTitleInput()
                    }
                })
                TextField("コメント", text: workoutRoutineComment, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutRoutineCommentInput()
                    }
                })
            }
            Section(header: Text("種目".uppercased())) {
                ForEach(workoutRoutineExercises) { workoutRoutineExercise in
                    NavigationLink(destination: WorkoutRoutineExerciseView(workoutRoutineExercise: workoutRoutineExercise)) {
                        VStack(alignment: .leading) {
                            Text(workoutRoutineExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "不明な種目")
                            workoutRoutineExercise.subtitle.map {
                                Text($0)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    let workoutRoutineExercises = self.workoutRoutineExercises
                    for i in offsets {
                        let workoutRoutineExercise = workoutRoutineExercises[i]
                        self.managedObjectContext.delete(workoutRoutineExercise)
                        workoutRoutineExercise.workoutRoutine?.removeFromWorkoutRoutineExercises(workoutRoutineExercise)
                    }
                    self.managedObjectContext.saveOrCrash()
                }
                .onMove { source, destination in
                    var workoutRoutineExercises = self.workoutRoutineExercises
                    workoutRoutineExercises.move(fromOffsets: source, toOffset: destination)
                    self.workoutRoutine.workoutRoutineExercises = NSOrderedSet(array: workoutRoutineExercises)
                    self.managedObjectContext.saveOrCrash()
                }

                Button(action: {
                    self.showExerciseSelector = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("種目を追加")
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationBarTitle(Text(workoutRoutine.displayTitle), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                Button(action: {
                    shareRoutine()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("共有")
                EditButton()
            }
        )
        .sheet(isPresented: self.$showExerciseSelector) {
            self.exerciseSelectorSheet
        }
        .overlay(ActivitySheet(activityItems: $shareItems))
    }

    private func shareRoutine() {
        var text = "[\(workoutRoutine.displayTitle)]\n\n"

        for (index, routineExercise) in workoutRoutineExercises.enumerated() {
            let exerciseName = routineExercise.exercise(in: exerciseStore.exercises)?.title ?? "不明な種目"
            let setsCount = routineExercise.workoutRoutineSets?.count ?? 0
            text += "\(index + 1). \(exerciseName) - \(setsCount) セット\n"
        }

        text += "\n#NanTon #筋トレ"

        shareItems = [text]
    }
}

#if DEBUG
struct WorkoutRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutRoutineView(workoutRoutine: MockWorkoutData.metric.workoutRoutine)
                .mockEnvironment(weightUnit: .metric)
        }
    }
}
#endif
