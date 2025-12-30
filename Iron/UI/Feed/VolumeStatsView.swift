//
//  VolumeStatsView.swift
//  Iron
//
//  Created for Nan Ton? app
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct VolumeStatsView: View {
    @Environment(\.calendar) var calendar
    @EnvironmentObject var settingsStore: SettingsStore

    @FetchRequest(fetchRequest: Workout.fetchRequest()) var weeklyWorkouts
    @FetchRequest(fetchRequest: Workout.fetchRequest()) var monthlyWorkouts
    @FetchRequest(fetchRequest: Workout.fetchRequest()) var previousWeekWorkouts
    @FetchRequest(fetchRequest: Workout.fetchRequest()) var previousMonthWorkouts

    init() {
        let now = Date()
        let calendar = Calendar.current

        // This week (from start of week to now)
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
        let weeklyRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        weeklyRequest.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true), startOfWeek as NSDate
        )
        weeklyRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._weeklyWorkouts = FetchRequest(fetchRequest: weeklyRequest)

        // Previous week
        let startOfPreviousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!
        let previousWeekRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        previousWeekRequest.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@ AND \(#keyPath(Workout.start)) < %@",
            NSNumber(booleanLiteral: true), startOfPreviousWeek as NSDate, startOfWeek as NSDate
        )
        previousWeekRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._previousWeekWorkouts = FetchRequest(fetchRequest: previousWeekRequest)

        // This month (from start of month to now)
        let startOfMonth = calendar.dateComponents([.calendar, .year, .month], from: now).date!
        let monthlyRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        monthlyRequest.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true), startOfMonth as NSDate
        )
        monthlyRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._monthlyWorkouts = FetchRequest(fetchRequest: monthlyRequest)

        // Previous month
        let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        let previousMonthRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        previousMonthRequest.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@ AND \(#keyPath(Workout.start)) < %@",
            NSNumber(booleanLiteral: true), startOfPreviousMonth as NSDate, startOfMonth as NSDate
        )
        previousMonthRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._previousMonthWorkouts = FetchRequest(fetchRequest: previousMonthRequest)
    }

    private func calculateVolume(for workouts: FetchedResults<Workout>) -> Double {
        workouts.map { $0.totalCompletedWeight ?? 0 }.reduce(0, +)
    }

    private func calculateSets(for workouts: FetchedResults<Workout>) -> Int {
        workouts.map { $0.numberOfCompletedSets ?? 0 }.reduce(0, +)
    }

    private func calculateReps(for workouts: FetchedResults<Workout>) -> Int {
        workouts.map { workout -> Int in
            (workout.workoutExercises?.array as? [WorkoutExercise])?.reduce(0) { total, exercise in
                total + (exercise.numberOfCompletedRepetitions ?? 0)
            } ?? 0
        }.reduce(0, +)
    }

    private func percentChange(current: Double, previous: Double) -> Double? {
        guard previous > 0 else { return nil }
        let change = (current / previous) - 1
        return abs(change) < 0.001 ? 0 : change
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Weekly Volume
            VStack(alignment: .leading, spacing: 8) {
                Text("今週のボリューム")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                let weeklyVolume = calculateVolume(for: weeklyWorkouts)
                let previousWeekVolume = calculateVolume(for: previousWeekWorkouts)
                let weeklyChange = percentChange(current: weeklyVolume, previous: previousWeekVolume)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(WeightUnit.format(weight: weeklyVolume, from: .metric, to: settingsStore.weightUnit))
                            .font(.title2)
                            .bold()
                        Text("\(weeklyWorkouts.count) ワークアウト / \(calculateSets(for: weeklyWorkouts)) セット")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let change = weeklyChange {
                        PercentChangeView(percent: change)
                    }
                }
            }

            Divider()

            // Monthly Volume
            VStack(alignment: .leading, spacing: 8) {
                Text("今月のボリューム")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                let monthlyVolume = calculateVolume(for: monthlyWorkouts)
                let previousMonthVolume = calculateVolume(for: previousMonthWorkouts)
                let monthlyChange = percentChange(current: monthlyVolume, previous: previousMonthVolume)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(WeightUnit.format(weight: monthlyVolume, from: .metric, to: settingsStore.weightUnit))
                            .font(.title2)
                            .bold()
                        Text("\(monthlyWorkouts.count) ワークアウト / \(calculateSets(for: monthlyWorkouts)) セット")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let change = monthlyChange {
                        PercentChangeView(percent: change)
                    }
                }
            }
        }
    }
}

private struct PercentChangeView: View {
    let percent: Double

    private static var percentNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .percent
        return formatter
    }()

    var body: some View {
        if percent != 0, let percentString = formatPercent() {
            HStack(spacing: 2) {
                Image(systemName: percent > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(percentString)
            }
            .foregroundColor(percent > 0 ? .green : .red)
            .font(.subheadline)
        }
    }

    private func formatPercent() -> String? {
        guard percent.isFinite else { return nil }
        return (percent > 0 ? "+" : "") + (Self.percentNumberFormatter.string(from: percent as NSNumber) ?? "\(String(format: "%.1f", percent * 100))%")
    }
}

struct VolumeStatsCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ボリューム統計")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)

            Text("週間・月間トレーニング量")
                .font(.headline)

            Divider()

            VolumeStatsView()
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct VolumeStatsView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            VolumeStatsCell()
                .mockEnvironment(weightUnit: .metric)
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}
#endif
