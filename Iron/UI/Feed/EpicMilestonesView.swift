//
//  EpicMilestonesView.swift
//  Iron
//
//  Created for Nan Ton? app
//

import SwiftUI
import CoreData
import WorkoutDataKit

// MARK: - Milestone Definitions

struct EpicMilestone: Identifiable {
    let id = UUID()
    let name: String
    let nameJP: String
    let weight: Double // in kg
    let emoji: String
    let description: String

    var formattedWeight: String {
        if weight >= 1000 {
            return String(format: "%.1f t", weight / 1000)
        } else {
            return String(format: "%.0f kg", weight)
        }
    }
}

// Famous landmarks and objects with their weights
let epicMilestones: [EpicMilestone] = [
    // Small milestones (early achievements)
    EpicMilestone(name: "Baby Elephant", nameJP: "象の赤ちゃん", weight: 120, emoji: "🐘", description: "生まれたての象の重さ"),
    EpicMilestone(name: "Gorilla", nameJP: "ゴリラ", weight: 200, emoji: "🦍", description: "オスのシルバーバック"),
    EpicMilestone(name: "Grand Piano", nameJP: "グランドピアノ", weight: 500, emoji: "🎹", description: "コンサートグランド"),
    EpicMilestone(name: "Horse", nameJP: "馬", weight: 600, emoji: "🐎", description: "サラブレッド"),
    EpicMilestone(name: "Polar Bear", nameJP: "シロクマ", weight: 700, emoji: "🐻‍❄️", description: "成獣のオス"),

    // Medium milestones
    EpicMilestone(name: "Smart Car", nameJP: "スマートカー", weight: 900, emoji: "🚗", description: "小型車"),
    EpicMilestone(name: "Great White Shark", nameJP: "ホオジロザメ", weight: 1100, emoji: "🦈", description: "海の捕食者"),
    EpicMilestone(name: "Hippo", nameJP: "カバ", weight: 1800, emoji: "🦛", description: "成獣"),
    EpicMilestone(name: "Car", nameJP: "乗用車", weight: 2000, emoji: "🚙", description: "平均的な車"),
    EpicMilestone(name: "Rhino", nameJP: "サイ", weight: 2500, emoji: "🦏", description: "アフリカサイ"),

    // Large milestones
    EpicMilestone(name: "Elephant", nameJP: "アフリカゾウ", weight: 6000, emoji: "🐘", description: "地上最大の動物"),
    EpicMilestone(name: "T-Rex", nameJP: "ティラノサウルス", weight: 9000, emoji: "🦖", description: "恐竜の王"),
    EpicMilestone(name: "School Bus", nameJP: "スクールバス", weight: 11000, emoji: "🚌", description: "アメリカンスクールバス"),
    EpicMilestone(name: "Fire Truck", nameJP: "消防車", weight: 19000, emoji: "🚒", description: "はしご車"),
    EpicMilestone(name: "Whale Shark", nameJP: "ジンベエザメ", weight: 20000, emoji: "🐋", description: "最大の魚"),

    // Epic milestones
    EpicMilestone(name: "Humpback Whale", nameJP: "ザトウクジラ", weight: 36000, emoji: "🐳", description: "海の歌い手"),
    EpicMilestone(name: "Semi Truck", nameJP: "トレーラー", weight: 40000, emoji: "🚛", description: "大型トラック"),
    EpicMilestone(name: "Space Shuttle", nameJP: "スペースシャトル", weight: 78000, emoji: "🚀", description: "オービター"),
    EpicMilestone(name: "Blue Whale", nameJP: "シロナガスクジラ", weight: 150000, emoji: "🐋", description: "地球最大の生物"),
    EpicMilestone(name: "Boeing 747", nameJP: "ジャンボジェット", weight: 178000, emoji: "✈️", description: "ボーイング747"),

    // Legendary milestones
    EpicMilestone(name: "Statue of Liberty", nameJP: "自由の女神", weight: 225000, emoji: "🗽", description: "ニューヨークのシンボル"),
    EpicMilestone(name: "ISS Module", nameJP: "国際宇宙ステーション", weight: 420000, emoji: "🛸", description: "宇宙ステーション"),
    EpicMilestone(name: "Eiffel Tower", nameJP: "エッフェル塔", weight: 7300000, emoji: "🗼", description: "パリのシンボル"),
    EpicMilestone(name: "Moai Statues", nameJP: "モアイ像（全部）", weight: 10000000, emoji: "🗿", description: "イースター島の全モアイ"),
    EpicMilestone(name: "Great Pyramid", nameJP: "ギザの大ピラミッド", weight: 6000000000, emoji: "⛰️", description: "古代の驚異"),
]

// MARK: - Epic Milestones View

struct EpicMilestonesView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore

    @FetchRequest(fetchRequest: Workout.fetchRequest()) var allWorkouts

    init() {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@",
            NSNumber(booleanLiteral: true)
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._allWorkouts = FetchRequest(fetchRequest: request)
    }

    // Calculate total lifetime volume
    private var totalLifetimeVolume: Double {
        allWorkouts.reduce(0) { total, workout in
            total + (workout.totalCompletedWeight ?? 0)
        }
    }

    // Find achieved and next milestones
    private var achievedMilestones: [EpicMilestone] {
        epicMilestones.filter { $0.weight <= totalLifetimeVolume }
    }

    private var nextMilestone: EpicMilestone? {
        epicMilestones.first { $0.weight > totalLifetimeVolume }
    }

    private var progressToNext: Double {
        guard let next = nextMilestone else { return 1.0 }
        let previous = achievedMilestones.last?.weight ?? 0
        let range = next.weight - previous
        let current = totalLifetimeVolume - previous
        return min(max(current / range, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Total volume header
            VStack(alignment: .leading, spacing: 4) {
                Text("累計挙上重量")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(formatWeight(totalLifetimeVolume))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Divider()

            // Latest achievement
            if let latest = achievedMilestones.last {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("達成済み")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(achievedMilestones.count) / \(epicMilestones.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Text(latest.emoji)
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(latest.nameJP)
                                .font(.headline)
                            Text(latest.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(latest.formattedWeight)
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }

                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            // Next milestone
            if let next = nextMilestone {
                VStack(alignment: .leading, spacing: 8) {
                    Text("次の目標")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Text(next.emoji)
                            .font(.system(size: 40))
                            .opacity(0.5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.nameJP)
                                .font(.headline)
                            Text(next.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(next.formattedWeight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Progress indicator
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: progressToNext)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(progressToNext * 100))%")
                                .font(.caption2)
                                .bold()
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progressToNext)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("あと \(formatWeight(next.weight - totalLifetimeVolume))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }

            // Achievement gallery (scrollable)
            if achievedMilestones.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("達成した記録")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(achievedMilestones.reversed().dropFirst().prefix(5)) { milestone in
                                VStack(spacing: 4) {
                                    Text(milestone.emoji)
                                        .font(.title2)
                                    Text(milestone.nameJP)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1_000_000 {
            return String(format: "%.2f 百万kg", weight / 1_000_000)
        } else if weight >= 1000 {
            return String(format: "%.1f t", weight / 1000)
        } else {
            return WeightUnit.format(weight: weight, from: .metric, to: settingsStore.weightUnit)
        }
    }
}

// MARK: - Cell for FeedView

struct EpicMilestonesCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("エピック・マイルストーン")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)

            Text("あなたの累計挙上重量")
                .font(.headline)

            Divider()

            EpicMilestonesView()
        }
        .padding([.top, .bottom], 8)
    }
}

// MARK: - Preview

#if DEBUG
struct EpicMilestonesView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EpicMilestonesCell()
                .mockEnvironment(weightUnit: .metric)
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}
#endif
