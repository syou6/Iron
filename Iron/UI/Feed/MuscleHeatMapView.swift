//
//  MuscleHeatMapView.swift
//  Iron
//
//  Created for Nan Ton? app
//

import SwiftUI
import CoreData
import WorkoutDataKit

// MARK: - Muscle Heat Map Data

enum MuscleGroup: String, CaseIterable {
    case chest = "胸"
    case back = "背中"
    case shoulders = "肩"
    case arms = "腕"
    case abs = "腹筋"
    case legs = "脚"

    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .arms: return .purple
        case .abs: return .yellow
        case .legs: return .green
        }
    }

    static func from(muscleGroupName: String) -> MuscleGroup? {
        return MuscleGroup(rawValue: muscleGroupName)
    }
}

// MARK: - Main View

struct MuscleHeatMapView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var exerciseStore: ExerciseStore

    @FetchRequest(fetchRequest: Workout.fetchRequest()) var recentWorkouts

    @State private var selectedView: HeatMapViewType = .front

    enum HeatMapViewType: String, CaseIterable {
        case front = "前面"
        case back = "背面"
    }

    init() {
        let now = Date()
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true), sevenDaysAgo as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        self._recentWorkouts = FetchRequest(fetchRequest: request)
    }

    // Calculate volume per muscle group
    private var muscleVolume: [MuscleGroup: Int] {
        var volume: [MuscleGroup: Int] = [:]
        MuscleGroup.allCases.forEach { volume[$0] = 0 }

        for workout in recentWorkouts {
            for workoutExercise in (workout.workoutExercises?.array as? [WorkoutExercise]) ?? [] {
                guard let uuid = workoutExercise.exerciseUuid,
                      let exercise = exerciseStore.find(with: uuid) else { continue }

                let completedSets = (workoutExercise.workoutSets?.array as? [WorkoutSet])?.filter { $0.isCompleted }.count ?? 0

                // Primary muscles get full credit
                for muscle in exercise.primaryMuscle {
                    if let groupName = Exercise.muscleGroup(for: muscle),
                       let group = MuscleGroup.from(muscleGroupName: groupName) {
                        volume[group, default: 0] += completedSets
                    }
                }

                // Secondary muscles get half credit
                for muscle in exercise.secondaryMuscle {
                    if let groupName = Exercise.muscleGroup(for: muscle),
                       let group = MuscleGroup.from(muscleGroupName: groupName) {
                        volume[group, default: 0] += completedSets / 2
                    }
                }
            }
        }

        return volume
    }

    private var maxVolume: Int {
        muscleVolume.values.max() ?? 1
    }

    private func intensity(for group: MuscleGroup) -> Double {
        guard maxVolume > 0 else { return 0 }
        return Double(muscleVolume[group] ?? 0) / Double(maxVolume)
    }

    var body: some View {
        VStack(spacing: 16) {
            // View selector
            Picker("表示", selection: $selectedView) {
                ForEach(HeatMapViewType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Body diagram
            ZStack {
                // Background glow effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [Color.black.opacity(0.8), Color.black.opacity(0.95)],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )

                if selectedView == .front {
                    FrontBodyView(muscleVolume: muscleVolume, maxVolume: maxVolume)
                } else {
                    BackBodyView(muscleVolume: muscleVolume, maxVolume: maxVolume)
                }
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Legend
            MuscleVolumeLegend(muscleVolume: muscleVolume)
        }
    }
}

// MARK: - Front Body View

struct FrontBodyView: View {
    let muscleVolume: [MuscleGroup: Int]
    let maxVolume: Int

    private func intensity(for group: MuscleGroup) -> Double {
        guard maxVolume > 0 else { return 0 }
        return Double(muscleVolume[group] ?? 0) / Double(maxVolume)
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 400
            let centerX = geometry.size.width / 2
            let offsetY = geometry.size.height * 0.05

            ZStack {
                // Body outline (silhouette)
                BodyOutlineFront()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Chest muscles
                ChestMuscleFront()
                    .fill(muscleGlow(for: .chest))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Shoulder muscles (deltoids)
                ShoulderMuscleFrontLeft()
                    .fill(muscleGlow(for: .shoulders))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                ShoulderMuscleFrontRight()
                    .fill(muscleGlow(for: .shoulders))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Arm muscles (biceps)
                BicepLeft()
                    .fill(muscleGlow(for: .arms))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                BicepRight()
                    .fill(muscleGlow(for: .arms))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Forearms
                ForearmFrontLeft()
                    .fill(muscleGlow(for: .arms).opacity(0.7))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                ForearmFrontRight()
                    .fill(muscleGlow(for: .arms).opacity(0.7))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Abs
                AbsMuscle()
                    .fill(muscleGlow(for: .abs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Obliques
                ObliquesLeft()
                    .fill(muscleGlow(for: .abs).opacity(0.8))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                ObliquesRight()
                    .fill(muscleGlow(for: .abs).opacity(0.8))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Quadriceps
                QuadLeft()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                QuadRight()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Calves (front)
                CalfFrontLeft()
                    .fill(muscleGlow(for: .legs).opacity(0.7))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                CalfFrontRight()
                    .fill(muscleGlow(for: .legs).opacity(0.7))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)
            }
        }
    }

    private func muscleGlow(for group: MuscleGroup) -> RadialGradient {
        let intensity = intensity(for: group)
        let baseColor = Color.red

        if intensity < 0.1 {
            return RadialGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                center: .center,
                startRadius: 0,
                endRadius: 50
            )
        }

        return RadialGradient(
            colors: [
                baseColor.opacity(intensity),
                baseColor.opacity(intensity * 0.7),
                baseColor.opacity(intensity * 0.3)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 50
        )
    }
}

// MARK: - Back Body View

struct BackBodyView: View {
    let muscleVolume: [MuscleGroup: Int]
    let maxVolume: Int

    private func intensity(for group: MuscleGroup) -> Double {
        guard maxVolume > 0 else { return 0 }
        return Double(muscleVolume[group] ?? 0) / Double(maxVolume)
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 400
            let centerX = geometry.size.width / 2
            let offsetY = geometry.size.height * 0.05

            ZStack {
                // Body outline
                BodyOutlineBack()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Trapezius
                TrapeziusMuscle()
                    .fill(muscleGlow(for: .back))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Rear deltoids
                RearDeltoidLeft()
                    .fill(muscleGlow(for: .shoulders))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                RearDeltoidRight()
                    .fill(muscleGlow(for: .shoulders))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Lats
                LatLeft()
                    .fill(muscleGlow(for: .back))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                LatRight()
                    .fill(muscleGlow(for: .back))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Triceps
                TricepLeft()
                    .fill(muscleGlow(for: .arms))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                TricepRight()
                    .fill(muscleGlow(for: .arms))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Lower back (erector spinae)
                LowerBack()
                    .fill(muscleGlow(for: .back).opacity(0.8))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Glutes
                GluteLeft()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                GluteRight()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Hamstrings
                HamstringLeft()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                HamstringRight()
                    .fill(muscleGlow(for: .legs))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                // Calves
                CalfBackLeft()
                    .fill(muscleGlow(for: .legs).opacity(0.8))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)

                CalfBackRight()
                    .fill(muscleGlow(for: .legs).opacity(0.8))
                    .scaleEffect(scale)
                    .position(x: centerX, y: geometry.size.height / 2 + offsetY)
            }
        }
    }

    private func muscleGlow(for group: MuscleGroup) -> RadialGradient {
        let intensity = intensity(for: group)
        let baseColor = Color.red

        if intensity < 0.1 {
            return RadialGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                center: .center,
                startRadius: 0,
                endRadius: 50
            )
        }

        return RadialGradient(
            colors: [
                baseColor.opacity(intensity),
                baseColor.opacity(intensity * 0.7),
                baseColor.opacity(intensity * 0.3)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 50
        )
    }
}

// MARK: - Muscle Volume Legend

struct MuscleVolumeLegend: View {
    let muscleVolume: [MuscleGroup: Int]

    private var sortedMuscles: [(MuscleGroup, Int)] {
        muscleVolume.sorted { $0.value > $1.value }
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(sortedMuscles, id: \.0) { group, sets in
                HStack(spacing: 4) {
                    Circle()
                        .fill(sets > 0 ? Color.red.opacity(Double(sets) / Double(max(muscleVolume.values.max() ?? 1, 1))) : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Text(group.rawValue)
                        .font(.caption2)
                    Text("\(sets)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Body Outline Shapes

struct BodyOutlineFront: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: 175, y: 5, width: 50, height: 55))

        // Neck
        path.move(to: CGPoint(x: 190, y: 55))
        path.addLine(to: CGPoint(x: 190, y: 70))
        path.move(to: CGPoint(x: 210, y: 55))
        path.addLine(to: CGPoint(x: 210, y: 70))

        // Shoulders and torso
        path.move(to: CGPoint(x: 190, y: 70))
        path.addQuadCurve(to: CGPoint(x: 130, y: 85), control: CGPoint(x: 150, y: 65))
        path.addLine(to: CGPoint(x: 115, y: 170))
        path.addLine(to: CGPoint(x: 135, y: 200))
        path.addLine(to: CGPoint(x: 145, y: 195))
        path.addLine(to: CGPoint(x: 155, y: 220))
        path.addLine(to: CGPoint(x: 175, y: 225))
        path.addLine(to: CGPoint(x: 175, y: 365))
        path.addLine(to: CGPoint(x: 160, y: 380))

        // Left leg
        path.addLine(to: CGPoint(x: 160, y: 380))

        // Continue with right side (mirrored)
        path.move(to: CGPoint(x: 210, y: 70))
        path.addQuadCurve(to: CGPoint(x: 270, y: 85), control: CGPoint(x: 250, y: 65))
        path.addLine(to: CGPoint(x: 285, y: 170))
        path.addLine(to: CGPoint(x: 265, y: 200))
        path.addLine(to: CGPoint(x: 255, y: 195))
        path.addLine(to: CGPoint(x: 245, y: 220))
        path.addLine(to: CGPoint(x: 225, y: 225))
        path.addLine(to: CGPoint(x: 225, y: 365))
        path.addLine(to: CGPoint(x: 240, y: 380))

        return path
    }
}

struct BodyOutlineBack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Same outline as front (simplified)
        path.addEllipse(in: CGRect(x: 175, y: 5, width: 50, height: 55))

        // Neck
        path.move(to: CGPoint(x: 190, y: 55))
        path.addLine(to: CGPoint(x: 190, y: 70))
        path.move(to: CGPoint(x: 210, y: 55))
        path.addLine(to: CGPoint(x: 210, y: 70))

        // Shoulders and torso
        path.move(to: CGPoint(x: 190, y: 70))
        path.addQuadCurve(to: CGPoint(x: 130, y: 85), control: CGPoint(x: 150, y: 65))
        path.addLine(to: CGPoint(x: 115, y: 170))
        path.addLine(to: CGPoint(x: 135, y: 200))
        path.addLine(to: CGPoint(x: 145, y: 195))
        path.addLine(to: CGPoint(x: 155, y: 220))
        path.addLine(to: CGPoint(x: 175, y: 225))
        path.addLine(to: CGPoint(x: 175, y: 365))

        path.move(to: CGPoint(x: 210, y: 70))
        path.addQuadCurve(to: CGPoint(x: 270, y: 85), control: CGPoint(x: 250, y: 65))
        path.addLine(to: CGPoint(x: 285, y: 170))
        path.addLine(to: CGPoint(x: 265, y: 200))
        path.addLine(to: CGPoint(x: 255, y: 195))
        path.addLine(to: CGPoint(x: 245, y: 220))
        path.addLine(to: CGPoint(x: 225, y: 225))
        path.addLine(to: CGPoint(x: 225, y: 365))

        return path
    }
}

// MARK: - Front Muscle Shapes

struct ChestMuscleFront: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Left pec
        path.move(to: CGPoint(x: 155, y: 80))
        path.addQuadCurve(to: CGPoint(x: 145, y: 120), control: CGPoint(x: 135, y: 95))
        path.addQuadCurve(to: CGPoint(x: 195, y: 125), control: CGPoint(x: 170, y: 135))
        path.addLine(to: CGPoint(x: 195, y: 80))
        path.addQuadCurve(to: CGPoint(x: 155, y: 80), control: CGPoint(x: 175, y: 70))

        // Right pec
        path.move(to: CGPoint(x: 245, y: 80))
        path.addQuadCurve(to: CGPoint(x: 255, y: 120), control: CGPoint(x: 265, y: 95))
        path.addQuadCurve(to: CGPoint(x: 205, y: 125), control: CGPoint(x: 230, y: 135))
        path.addLine(to: CGPoint(x: 205, y: 80))
        path.addQuadCurve(to: CGPoint(x: 245, y: 80), control: CGPoint(x: 225, y: 70))

        return path
    }
}

struct ShoulderMuscleFrontLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 150, y: 72))
        path.addQuadCurve(to: CGPoint(x: 130, y: 100), control: CGPoint(x: 125, y: 80))
        path.addQuadCurve(to: CGPoint(x: 145, y: 115), control: CGPoint(x: 130, y: 110))
        path.addQuadCurve(to: CGPoint(x: 150, y: 72), control: CGPoint(x: 155, y: 90))
        return path
    }
}

struct ShoulderMuscleFrontRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 250, y: 72))
        path.addQuadCurve(to: CGPoint(x: 270, y: 100), control: CGPoint(x: 275, y: 80))
        path.addQuadCurve(to: CGPoint(x: 255, y: 115), control: CGPoint(x: 270, y: 110))
        path.addQuadCurve(to: CGPoint(x: 250, y: 72), control: CGPoint(x: 245, y: 90))
        return path
    }
}

struct BicepLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 130, y: 105))
        path.addQuadCurve(to: CGPoint(x: 120, y: 155), control: CGPoint(x: 115, y: 130))
        path.addQuadCurve(to: CGPoint(x: 135, y: 165), control: CGPoint(x: 125, y: 162))
        path.addQuadCurve(to: CGPoint(x: 145, y: 115), control: CGPoint(x: 145, y: 135))
        path.addQuadCurve(to: CGPoint(x: 130, y: 105), control: CGPoint(x: 138, y: 108))
        return path
    }
}

struct BicepRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 270, y: 105))
        path.addQuadCurve(to: CGPoint(x: 280, y: 155), control: CGPoint(x: 285, y: 130))
        path.addQuadCurve(to: CGPoint(x: 265, y: 165), control: CGPoint(x: 275, y: 162))
        path.addQuadCurve(to: CGPoint(x: 255, y: 115), control: CGPoint(x: 255, y: 135))
        path.addQuadCurve(to: CGPoint(x: 270, y: 105), control: CGPoint(x: 262, y: 108))
        return path
    }
}

struct ForearmFrontLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 120, y: 160))
        path.addQuadCurve(to: CGPoint(x: 135, y: 200), control: CGPoint(x: 115, y: 180))
        path.addLine(to: CGPoint(x: 145, y: 195))
        path.addQuadCurve(to: CGPoint(x: 140, y: 165), control: CGPoint(x: 145, y: 178))
        path.closeSubpath()
        return path
    }
}

struct ForearmFrontRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 280, y: 160))
        path.addQuadCurve(to: CGPoint(x: 265, y: 200), control: CGPoint(x: 285, y: 180))
        path.addLine(to: CGPoint(x: 255, y: 195))
        path.addQuadCurve(to: CGPoint(x: 260, y: 165), control: CGPoint(x: 255, y: 178))
        path.closeSubpath()
        return path
    }
}

struct AbsMuscle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Six-pack abs
        // Top row
        path.addRoundedRect(in: CGRect(x: 183, y: 125, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 202, y: 125, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))

        // Middle row
        path.addRoundedRect(in: CGRect(x: 183, y: 148, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 202, y: 148, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))

        // Bottom row
        path.addRoundedRect(in: CGRect(x: 183, y: 171, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: 202, y: 171, width: 15, height: 20), cornerSize: CGSize(width: 3, height: 3))

        return path
    }
}

struct ObliquesLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 160, y: 125))
        path.addQuadCurve(to: CGPoint(x: 155, y: 195), control: CGPoint(x: 145, y: 160))
        path.addLine(to: CGPoint(x: 175, y: 195))
        path.addLine(to: CGPoint(x: 180, y: 125))
        path.closeSubpath()
        return path
    }
}

struct ObliquesRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 240, y: 125))
        path.addQuadCurve(to: CGPoint(x: 245, y: 195), control: CGPoint(x: 255, y: 160))
        path.addLine(to: CGPoint(x: 225, y: 195))
        path.addLine(to: CGPoint(x: 220, y: 125))
        path.closeSubpath()
        return path
    }
}

struct QuadLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 175, y: 225))
        path.addQuadCurve(to: CGPoint(x: 160, y: 320), control: CGPoint(x: 155, y: 270))
        path.addQuadCurve(to: CGPoint(x: 175, y: 320), control: CGPoint(x: 168, y: 325))
        path.addLine(to: CGPoint(x: 195, y: 225))
        path.closeSubpath()
        return path
    }
}

struct QuadRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 225, y: 225))
        path.addQuadCurve(to: CGPoint(x: 240, y: 320), control: CGPoint(x: 245, y: 270))
        path.addQuadCurve(to: CGPoint(x: 225, y: 320), control: CGPoint(x: 232, y: 325))
        path.addLine(to: CGPoint(x: 205, y: 225))
        path.closeSubpath()
        return path
    }
}

struct CalfFrontLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 162, y: 330))
        path.addQuadCurve(to: CGPoint(x: 158, y: 385), control: CGPoint(x: 150, y: 355))
        path.addQuadCurve(to: CGPoint(x: 178, y: 385), control: CGPoint(x: 168, y: 390))
        path.addQuadCurve(to: CGPoint(x: 175, y: 330), control: CGPoint(x: 180, y: 355))
        path.closeSubpath()
        return path
    }
}

struct CalfFrontRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 238, y: 330))
        path.addQuadCurve(to: CGPoint(x: 242, y: 385), control: CGPoint(x: 250, y: 355))
        path.addQuadCurve(to: CGPoint(x: 222, y: 385), control: CGPoint(x: 232, y: 390))
        path.addQuadCurve(to: CGPoint(x: 225, y: 330), control: CGPoint(x: 220, y: 355))
        path.closeSubpath()
        return path
    }
}

// MARK: - Back Muscle Shapes

struct TrapeziusMuscle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 200, y: 60))
        path.addQuadCurve(to: CGPoint(x: 150, y: 80), control: CGPoint(x: 170, y: 65))
        path.addQuadCurve(to: CGPoint(x: 170, y: 125), control: CGPoint(x: 155, y: 100))
        path.addLine(to: CGPoint(x: 200, y: 110))
        path.addLine(to: CGPoint(x: 230, y: 125))
        path.addQuadCurve(to: CGPoint(x: 250, y: 80), control: CGPoint(x: 245, y: 100))
        path.addQuadCurve(to: CGPoint(x: 200, y: 60), control: CGPoint(x: 230, y: 65))
        return path
    }
}

struct RearDeltoidLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 148, y: 75))
        path.addQuadCurve(to: CGPoint(x: 130, y: 105), control: CGPoint(x: 125, y: 85))
        path.addQuadCurve(to: CGPoint(x: 148, y: 115), control: CGPoint(x: 135, y: 115))
        path.addQuadCurve(to: CGPoint(x: 148, y: 75), control: CGPoint(x: 155, y: 95))
        return path
    }
}

struct RearDeltoidRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 252, y: 75))
        path.addQuadCurve(to: CGPoint(x: 270, y: 105), control: CGPoint(x: 275, y: 85))
        path.addQuadCurve(to: CGPoint(x: 252, y: 115), control: CGPoint(x: 265, y: 115))
        path.addQuadCurve(to: CGPoint(x: 252, y: 75), control: CGPoint(x: 245, y: 95))
        return path
    }
}

struct LatLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 165, y: 100))
        path.addQuadCurve(to: CGPoint(x: 145, y: 130), control: CGPoint(x: 145, y: 115))
        path.addQuadCurve(to: CGPoint(x: 155, y: 195), control: CGPoint(x: 140, y: 165))
        path.addLine(to: CGPoint(x: 180, y: 195))
        path.addLine(to: CGPoint(x: 185, y: 125))
        path.addQuadCurve(to: CGPoint(x: 165, y: 100), control: CGPoint(x: 175, y: 105))
        return path
    }
}

struct LatRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 235, y: 100))
        path.addQuadCurve(to: CGPoint(x: 255, y: 130), control: CGPoint(x: 255, y: 115))
        path.addQuadCurve(to: CGPoint(x: 245, y: 195), control: CGPoint(x: 260, y: 165))
        path.addLine(to: CGPoint(x: 220, y: 195))
        path.addLine(to: CGPoint(x: 215, y: 125))
        path.addQuadCurve(to: CGPoint(x: 235, y: 100), control: CGPoint(x: 225, y: 105))
        return path
    }
}

struct TricepLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 135, y: 105))
        path.addQuadCurve(to: CGPoint(x: 125, y: 160), control: CGPoint(x: 120, y: 135))
        path.addQuadCurve(to: CGPoint(x: 145, y: 165), control: CGPoint(x: 135, y: 168))
        path.addQuadCurve(to: CGPoint(x: 148, y: 115), control: CGPoint(x: 150, y: 140))
        path.closeSubpath()
        return path
    }
}

struct TricepRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 265, y: 105))
        path.addQuadCurve(to: CGPoint(x: 275, y: 160), control: CGPoint(x: 280, y: 135))
        path.addQuadCurve(to: CGPoint(x: 255, y: 165), control: CGPoint(x: 265, y: 168))
        path.addQuadCurve(to: CGPoint(x: 252, y: 115), control: CGPoint(x: 250, y: 140))
        path.closeSubpath()
        return path
    }
}

struct LowerBack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 175, y: 145))
        path.addLine(to: CGPoint(x: 165, y: 200))
        path.addQuadCurve(to: CGPoint(x: 200, y: 210), control: CGPoint(x: 180, y: 215))
        path.addQuadCurve(to: CGPoint(x: 235, y: 200), control: CGPoint(x: 220, y: 215))
        path.addLine(to: CGPoint(x: 225, y: 145))
        path.addQuadCurve(to: CGPoint(x: 175, y: 145), control: CGPoint(x: 200, y: 140))
        return path
    }
}

struct GluteLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 155, y: 205, width: 45, height: 35))
        return path
    }
}

struct GluteRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 200, y: 205, width: 45, height: 35))
        return path
    }
}

struct HamstringLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 160, y: 245))
        path.addQuadCurve(to: CGPoint(x: 158, y: 325), control: CGPoint(x: 150, y: 285))
        path.addQuadCurve(to: CGPoint(x: 178, y: 325), control: CGPoint(x: 168, y: 330))
        path.addQuadCurve(to: CGPoint(x: 195, y: 245), control: CGPoint(x: 195, y: 285))
        path.closeSubpath()
        return path
    }
}

struct HamstringRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 240, y: 245))
        path.addQuadCurve(to: CGPoint(x: 242, y: 325), control: CGPoint(x: 250, y: 285))
        path.addQuadCurve(to: CGPoint(x: 222, y: 325), control: CGPoint(x: 232, y: 330))
        path.addQuadCurve(to: CGPoint(x: 205, y: 245), control: CGPoint(x: 205, y: 285))
        path.closeSubpath()
        return path
    }
}

struct CalfBackLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 160, y: 330))
        path.addQuadCurve(to: CGPoint(x: 155, y: 385), control: CGPoint(x: 148, y: 355))
        path.addQuadCurve(to: CGPoint(x: 180, y: 385), control: CGPoint(x: 168, y: 395))
        path.addQuadCurve(to: CGPoint(x: 178, y: 330), control: CGPoint(x: 185, y: 355))
        path.closeSubpath()
        return path
    }
}

struct CalfBackRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 240, y: 330))
        path.addQuadCurve(to: CGPoint(x: 245, y: 385), control: CGPoint(x: 252, y: 355))
        path.addQuadCurve(to: CGPoint(x: 220, y: 385), control: CGPoint(x: 232, y: 395))
        path.addQuadCurve(to: CGPoint(x: 222, y: 330), control: CGPoint(x: 215, y: 355))
        path.closeSubpath()
        return path
    }
}

// MARK: - Cell for FeedView

struct MuscleHeatMapCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("マッスルヒートマップ")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)

            Text("今週鍛えた部位")
                .font(.headline)

            Divider()

            MuscleHeatMapView()
        }
        .padding([.top, .bottom], 8)
    }
}

// MARK: - Preview

#if DEBUG
struct MuscleHeatMapView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MuscleHeatMapCell()
                .mockEnvironment(weightUnit: .metric)
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}
#endif
