//
//  ProgressiveOverloadView.swift
//  Iron
//
//  Created for Nan Ton? app
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct ProgressiveOverloadView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore

    @FetchRequest(fetchRequest: Workout.fetchRequest()) var recentWorkouts

    init() {
        let now = Date()
        let calendar = Calendar.current

        // Get workouts from last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true), thirtyDaysAgo as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._recentWorkouts = FetchRequest(fetchRequest: request)
    }

    struct ExerciseProgress: Identifiable {
        let id: UUID
        let exerciseTitle: String
        let currentMax: Double
        let previousMax: Double
        let improvement: Double
        let isNewPR: Bool
    }

    private var exerciseProgressList: [ExerciseProgress] {
        // Get all exercises performed in recent workouts
        var exerciseData: [UUID: (current: [Double], previous: [Double])] = [:]

        let calendar = Calendar.current
        let now = Date()
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: now)!

        for workout in recentWorkouts {
            guard let start = workout.start else { continue }
            let isRecent = start >= fifteenDaysAgo

            for workoutExercise in (workout.workoutExercises?.array as? [WorkoutExercise]) ?? [] {
                guard let uuid = workoutExercise.exerciseUuid else { continue }
                guard let sets = workoutExercise.workoutSets?.array as? [WorkoutSet] else { continue }

                let maxWeight = sets.compactMap { $0.isCompleted ? $0.weightValue : nil }.max() ?? 0

                if exerciseData[uuid] == nil {
                    exerciseData[uuid] = (current: [], previous: [])
                }

                if isRecent {
                    exerciseData[uuid]?.current.append(maxWeight)
                } else {
                    exerciseData[uuid]?.previous.append(maxWeight)
                }
            }
        }

        // Calculate progress for each exercise
        var progressList: [ExerciseProgress] = []

        for (uuid, data) in exerciseData {
            guard !data.current.isEmpty else { continue }

            let currentMax = data.current.max() ?? 0
            let previousMax = data.previous.max() ?? 0

            guard currentMax > 0 else { continue }

            let improvement: Double
            if previousMax > 0 {
                improvement = ((currentMax - previousMax) / previousMax) * 100
            } else {
                improvement = 0
            }

            let exerciseTitle = exerciseStore.find(with: uuid)?.title ?? "不明な種目"

            progressList.append(ExerciseProgress(
                id: uuid,
                exerciseTitle: exerciseTitle,
                currentMax: currentMax,
                previousMax: previousMax,
                improvement: improvement,
                isNewPR: currentMax > previousMax && previousMax > 0
            ))
        }

        // Sort by improvement (descending)
        return progressList.sorted { $0.improvement > $1.improvement }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if exerciseProgressList.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(exerciseProgressList.prefix(5)) { progress in
                    ProgressRow(progress: progress, weightUnit: settingsStore.weightUnit)
                }
            }
        }
    }
}

private struct ProgressRow: View {
    let progress: ProgressiveOverloadView.ExerciseProgress
    let weightUnit: WeightUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(progress.exerciseTitle)
                        .font(.subheadline)
                        .lineLimit(1)

                    if progress.isNewPR {
                        Text("PR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 4) {
                    Text(WeightUnit.format(weight: progress.currentMax, from: .metric, to: weightUnit))
                        .font(.caption)
                        .foregroundColor(.primary)

                    if progress.previousMax > 0 {
                        Text("(前回: \(WeightUnit.format(weight: progress.previousMax, from: .metric, to: weightUnit)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if progress.previousMax > 0 {
                HStack(spacing: 2) {
                    Image(systemName: progress.improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%.1f%%", abs(progress.improvement)))
                        .font(.caption)
                }
                .foregroundColor(progress.improvement >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressiveOverloadCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("進捗追跡")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)

            Text("Progressive Overload")
                .font(.headline)

            Divider()

            ProgressiveOverloadView()
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct ProgressiveOverloadView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProgressiveOverloadCell()
                .mockEnvironment(weightUnit: .metric)
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}
#endif
