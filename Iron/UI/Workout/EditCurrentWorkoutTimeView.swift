//
//  EditCurrentWorkoutTimeView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 14.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct EditCurrentWorkoutTimeView: View {
    @ObservedObject var workout: Workout
    
    var automaticTimeTracking: Binding<Bool> {
        Binding(
            get: {
                self.workout.end == nil
            },
            set: { enabled in
                if enabled {
                    precondition(self.workout.isCurrentWorkout)
                    self.workout.end = nil
                } else {
                    self.workout.end = self.workout.safeEnd
                }
            }
        )
    }

    var body: some View {
        List {
            Section {
                DatePicker(selection: $workout.safeStart, in: ...min(workout.safeEnd, Date())) {
                    Text("開始")
                }

                Toggle("自動時間記録", isOn: automaticTimeTracking)

                if !automaticTimeTracking.wrappedValue {
                    DatePicker(selection: $workout.safeEnd, in: workout.safeStart...Date()) {
                        Text("終了")
                    }
                }
            }

            Section {
                Button("開始時刻をリセット") {
                    let newStart = Date()
                    if let end = self.workout.end, end < newStart {
                        self.workout.end = newStart
                    }
                    self.workout.start = newStart
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}

#if DEBUG
struct EditCurrentWorkoutTimeView_Previews: PreviewProvider {
    static var previews: some View {
        EditCurrentWorkoutTimeView(workout: MockWorkoutData.metricRandom.currentWorkout)
    }
}
#endif
