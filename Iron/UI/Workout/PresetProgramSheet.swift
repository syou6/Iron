//
//  PresetProgramSheet.swift
//  Iron
//
//  Created for Nan Ton? app
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct PresetProgramSheet: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var exerciseStore: ExerciseStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(PresetPrograms.allPrograms) { program in
                    NavigationLink(destination: PresetProgramDetailView(program: program, onAdd: addProgram)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.name)
                                .font(.headline)
                            Text(program.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(program.routines.count) ルーティン")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .navigationTitle("プリセットプログラム")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func addProgram(_ program: PresetProgram) {
        let workoutPlan = WorkoutPlan.create(context: managedObjectContext)
        workoutPlan.title = program.name

        for presetRoutine in program.routines {
            let workoutRoutine = WorkoutRoutine.create(context: managedObjectContext)
            workoutRoutine.workoutPlan = workoutPlan
            workoutRoutine.title = presetRoutine.name

            for presetExercise in presetRoutine.exercises {
                if let exercise = exerciseStore.exercises.first(where: { $0.everkineticId == presetExercise.everkineticId }) {
                    let workoutRoutineExercise = WorkoutRoutineExercise.create(context: managedObjectContext)
                    workoutRoutineExercise.workoutRoutine = workoutRoutine
                    workoutRoutineExercise.exerciseUuid = exercise.uuid

                    // Add sets
                    for _ in 0..<presetExercise.sets {
                        let workoutRoutineSet = WorkoutRoutineSet.create(context: managedObjectContext)
                        workoutRoutineSet.workoutRoutineExercise = workoutRoutineExercise
                        workoutRoutineSet.minRepetitionsValue = Int16(presetExercise.reps)
                        workoutRoutineSet.maxRepetitionsValue = Int16(presetExercise.reps)
                    }
                }
            }
        }

        managedObjectContext.saveOrCrash()
        presentationMode.wrappedValue.dismiss()
    }
}

private struct PresetProgramDetailView: View {
    let program: PresetProgram
    let onAdd: (PresetProgram) -> Void

    @EnvironmentObject var exerciseStore: ExerciseStore

    var body: some View {
        List {
            Section {
                Text(program.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(program.routines, id: \.name) { routine in
                Section(header: Text(routine.name)) {
                    ForEach(routine.exercises, id: \.everkineticId) { exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exerciseName(for: exercise.everkineticId))
                                    .font(.subheadline)
                                Text("\(exercise.sets) セット x \(exercise.reps) レップ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }

            Section {
                Button(action: {
                    onAdd(program)
                }) {
                    HStack {
                        Spacer()
                        Text("このプログラムを追加")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exerciseName(for everkineticId: Int) -> String {
        exerciseStore.exercises.first(where: { $0.everkineticId == everkineticId })?.title ?? "不明な種目"
    }
}

#if DEBUG
struct PresetProgramSheet_Previews: PreviewProvider {
    static var previews: some View {
        PresetProgramSheet()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
