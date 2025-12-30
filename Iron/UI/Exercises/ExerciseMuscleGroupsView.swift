//
//  ExerciseCategoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct ExerciseMuscleGroupsView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    // select the all exercises tab by default on iPad
    @State private var allExercisesSelected = UIDevice.current.userInterfaceIdiom == .pad ? true : false
    
    func exerciseGroupCell(exercises: [Exercise]) -> some View {
        let muscleGroup = exercises.first?.muscleGroup ?? ""
        return NavigationLink(destination:
            ExercisesView(exercises: exercises)
                .navigationBarTitle(Text(muscleGroup.capitalized), displayMode: .inline)
        ) {
            HStack {
                Text(muscleGroup.capitalized)
                Spacer()
                Text("(\(exercises.count))")
                    .foregroundColor(.secondary)
                Exercise.imageFor(muscleGroup: muscleGroup)
                    .foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
            }
        }
    }
    
    private var exerciseGroups: [ExerciseGroup] {
        ExerciseStore.splitIntoMuscleGroups(exercises: exerciseStore.shownExercises)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: AllExercisesView(exerciseGroups: exerciseGroups), isActive: $allExercisesSelected) {
                        HStack {
                            Text("すべて")
                            Spacer()
                            Text("(\(exerciseStore.shownExercises.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    ForEach(exerciseGroups) { exerciseGroup in
                        self.exerciseGroupCell(exercises: exerciseGroup.exercises)
                    }
                }

                Section {
                    NavigationLink(destination:
                        CustomExercisesView()
                            .navigationBarTitle(Text("カスタム"), displayMode: .inline)
                    ) {
                        HStack {
                            Text("カスタム")
                            Spacer()
                            Text("(\(exerciseStore.customExercises.count))")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !exerciseStore.hiddenExercises.isEmpty {
                        NavigationLink(destination:
                            ExercisesView(exercises: exerciseStore.hiddenExercises)
                                .navigationBarTitle(Text("非表示"), displayMode: .inline)
                        ) {
                            HStack {
                                Text("非表示")
                                Spacer()
                                Text("(\(exerciseStore.hiddenExercises.count))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .navigationBarTitle("種目")
        }
        .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0) // hack that makes the master view show on iPad on portrait mode
    }
}

private struct AllExercisesView: View {
    @ObservedObject private var filter: ExerciseGroupFilter
    
    init(exerciseGroups: [ExerciseGroup]) {
        self.filter = ExerciseGroupFilter(exerciseGroups: exerciseGroups)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("検索", text: $filter.filter)
                .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                .padding()

            Divider()

            MuscleGroupSectionedExercisesView(exerciseGroups: filter.exerciseGroups)
        }
        .navigationBarTitle(Text("すべての種目"), displayMode: .inline)
    }
}

#if DEBUG
struct ExerciseCategoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseMuscleGroupsView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
