//
//  MuscleHeatMap3DView.swift
//  Iron
//
//  Created for Nan Ton? app
//  3D Muscle Heat Map using SceneKit
//

import SwiftUI
import SceneKit
import CoreData
import WorkoutDataKit

// MARK: - 3D Muscle Heat Map View

struct MuscleHeatMap3DView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var exerciseStore: ExerciseStore

    @FetchRequest(fetchRequest: Workout.fetchRequest()) var recentWorkouts

    @State private var scene: SCNScene = SCNScene()
    @State private var cameraNode: SCNNode = SCNNode()
    @State private var rotationAngle: Float = 0

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

                for muscle in exercise.primaryMuscle {
                    if let groupName = Exercise.muscleGroup(for: muscle),
                       let group = MuscleGroup.from(muscleGroupName: groupName) {
                        volume[group, default: 0] += completedSets
                    }
                }

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
            // 3D Scene View
            SceneView(
                scene: createScene(),
                pointOfView: createCamera(),
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .frame(height: 350)
            .background(
                LinearGradient(
                    colors: [Color.black, Color(white: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Legend
            MuscleVolumeLegend3D(muscleVolume: muscleVolume)
        }
    }

    // MARK: - Scene Creation

    private func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black

        // Add body parts
        addBodyToScene(scene)

        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(5, 10, 10)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)

        return scene
    }

    private func createCamera() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 1, 5)
        cameraNode.look(at: SCNVector3(0, 0.5, 0))
        return cameraNode
    }

    // MARK: - Body Model Creation

    private func addBodyToScene(_ scene: SCNScene) {
        let bodyNode = SCNNode()

        // Head
        let head = createSphere(radius: 0.25, color: .gray)
        head.position = SCNVector3(0, 2.1, 0)
        bodyNode.addChildNode(head)

        // Neck
        let neck = createCylinder(radius: 0.08, height: 0.15, color: .gray)
        neck.position = SCNVector3(0, 1.85, 0)
        bodyNode.addChildNode(neck)

        // Chest (胸)
        let chestIntensity = intensity(for: .chest)
        let chest = createBox(width: 0.6, height: 0.4, length: 0.25, color: heatColor(intensity: chestIntensity))
        chest.position = SCNVector3(0, 1.5, 0.05)
        chest.name = "chest"
        bodyNode.addChildNode(chest)

        // Abs (腹筋)
        let absIntensity = intensity(for: .abs)
        let abs = createBox(width: 0.45, height: 0.4, length: 0.2, color: heatColor(intensity: absIntensity))
        abs.position = SCNVector3(0, 1.05, 0.03)
        abs.name = "abs"
        bodyNode.addChildNode(abs)

        // Back (背中) - behind the body
        let backIntensity = intensity(for: .back)
        let back = createBox(width: 0.55, height: 0.7, length: 0.15, color: heatColor(intensity: backIntensity))
        back.position = SCNVector3(0, 1.3, -0.15)
        back.name = "back"
        bodyNode.addChildNode(back)

        // Shoulders (肩)
        let shoulderIntensity = intensity(for: .shoulders)
        let leftShoulder = createSphere(radius: 0.12, color: heatColor(intensity: shoulderIntensity))
        leftShoulder.position = SCNVector3(-0.38, 1.65, 0)
        leftShoulder.name = "shoulder_left"
        bodyNode.addChildNode(leftShoulder)

        let rightShoulder = createSphere(radius: 0.12, color: heatColor(intensity: shoulderIntensity))
        rightShoulder.position = SCNVector3(0.38, 1.65, 0)
        rightShoulder.name = "shoulder_right"
        bodyNode.addChildNode(rightShoulder)

        // Arms (腕)
        let armIntensity = intensity(for: .arms)

        // Upper arms (biceps/triceps)
        let leftUpperArm = createCapsule(radius: 0.08, height: 0.35, color: heatColor(intensity: armIntensity))
        leftUpperArm.position = SCNVector3(-0.45, 1.35, 0)
        leftUpperArm.name = "arm_upper_left"
        bodyNode.addChildNode(leftUpperArm)

        let rightUpperArm = createCapsule(radius: 0.08, height: 0.35, color: heatColor(intensity: armIntensity))
        rightUpperArm.position = SCNVector3(0.45, 1.35, 0)
        rightUpperArm.name = "arm_upper_right"
        bodyNode.addChildNode(rightUpperArm)

        // Forearms
        let leftForearm = createCapsule(radius: 0.06, height: 0.3, color: heatColor(intensity: armIntensity * 0.7))
        leftForearm.position = SCNVector3(-0.45, 0.95, 0)
        leftForearm.name = "arm_lower_left"
        bodyNode.addChildNode(leftForearm)

        let rightForearm = createCapsule(radius: 0.06, height: 0.3, color: heatColor(intensity: armIntensity * 0.7))
        rightForearm.position = SCNVector3(0.45, 0.95, 0)
        rightForearm.name = "arm_lower_right"
        bodyNode.addChildNode(rightForearm)

        // Hips/Pelvis
        let pelvis = createBox(width: 0.45, height: 0.2, length: 0.2, color: .darkGray)
        pelvis.position = SCNVector3(0, 0.75, 0)
        bodyNode.addChildNode(pelvis)

        // Legs (脚)
        let legIntensity = intensity(for: .legs)

        // Upper legs (quads/hamstrings)
        let leftUpperLeg = createCapsule(radius: 0.1, height: 0.45, color: heatColor(intensity: legIntensity))
        leftUpperLeg.position = SCNVector3(-0.15, 0.4, 0)
        leftUpperLeg.name = "leg_upper_left"
        bodyNode.addChildNode(leftUpperLeg)

        let rightUpperLeg = createCapsule(radius: 0.1, height: 0.45, color: heatColor(intensity: legIntensity))
        rightUpperLeg.position = SCNVector3(0.15, 0.4, 0)
        rightUpperLeg.name = "leg_upper_right"
        bodyNode.addChildNode(rightUpperLeg)

        // Lower legs (calves)
        let leftLowerLeg = createCapsule(radius: 0.07, height: 0.4, color: heatColor(intensity: legIntensity * 0.8))
        leftLowerLeg.position = SCNVector3(-0.15, -0.1, 0)
        leftLowerLeg.name = "leg_lower_left"
        bodyNode.addChildNode(leftLowerLeg)

        let rightLowerLeg = createCapsule(radius: 0.07, height: 0.4, color: heatColor(intensity: legIntensity * 0.8))
        rightLowerLeg.position = SCNVector3(0.15, -0.1, 0)
        rightLowerLeg.name = "leg_lower_right"
        bodyNode.addChildNode(rightLowerLeg)

        // Glutes (臀部)
        let gluteLeft = createSphere(radius: 0.12, color: heatColor(intensity: legIntensity * 0.9))
        gluteLeft.position = SCNVector3(-0.12, 0.68, -0.1)
        gluteLeft.name = "glute_left"
        bodyNode.addChildNode(gluteLeft)

        let gluteRight = createSphere(radius: 0.12, color: heatColor(intensity: legIntensity * 0.9))
        gluteRight.position = SCNVector3(0.12, 0.68, -0.1)
        gluteRight.name = "glute_right"
        bodyNode.addChildNode(gluteRight)

        // Add glow effect for active muscles
        addGlowEffects(to: bodyNode)

        scene.rootNode.addChildNode(bodyNode)
    }

    // MARK: - Geometry Helpers

    private func createSphere(radius: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.segmentCount = 32
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.specular.contents = UIColor.white
        geometry.firstMaterial?.shininess = 0.3
        return SCNNode(geometry: geometry)
    }

    private func createCylinder(radius: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNCylinder(radius: radius, height: height)
        geometry.radialSegmentCount = 24
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.specular.contents = UIColor.white
        return SCNNode(geometry: geometry)
    }

    private func createCapsule(radius: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNCapsule(capRadius: radius, height: height)
        geometry.radialSegmentCount = 24
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.specular.contents = UIColor.white
        geometry.firstMaterial?.shininess = 0.3
        return SCNNode(geometry: geometry)
    }

    private func createBox(width: CGFloat, height: CGFloat, length: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.02)
        geometry.firstMaterial?.diffuse.contents = color
        geometry.firstMaterial?.specular.contents = UIColor.white
        geometry.firstMaterial?.shininess = 0.3
        return SCNNode(geometry: geometry)
    }

    // MARK: - Color & Effects

    private func heatColor(intensity: Double) -> UIColor {
        if intensity < 0.1 {
            return UIColor(white: 0.3, alpha: 1.0)
        }

        // Gradient from dark red to bright red/orange
        let red = min(1.0, 0.3 + intensity * 0.7)
        let green = max(0, intensity * 0.3 - 0.1)
        let blue = 0.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    private func addGlowEffects(to bodyNode: SCNNode) {
        for child in bodyNode.childNodes {
            guard let name = child.name, let geometry = child.geometry else { continue }

            // Check if this muscle has significant volume
            var muscleIntensity: Double = 0

            if name.contains("chest") {
                muscleIntensity = intensity(for: .chest)
            } else if name.contains("abs") {
                muscleIntensity = intensity(for: .abs)
            } else if name.contains("back") {
                muscleIntensity = intensity(for: .back)
            } else if name.contains("shoulder") {
                muscleIntensity = intensity(for: .shoulders)
            } else if name.contains("arm") {
                muscleIntensity = intensity(for: .arms)
            } else if name.contains("leg") || name.contains("glute") {
                muscleIntensity = intensity(for: .legs)
            }

            // Add emission for active muscles (glow effect)
            if muscleIntensity > 0.2 {
                let emissionIntensity = muscleIntensity * 0.5
                geometry.firstMaterial?.emission.contents = UIColor(
                    red: emissionIntensity,
                    green: emissionIntensity * 0.2,
                    blue: 0,
                    alpha: 1.0
                )
            }
        }
    }
}

// MARK: - Legend

struct MuscleVolumeLegend3D: View {
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

// MARK: - Cell for FeedView

struct MuscleHeatMap3DCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("マッスルヒートマップ")
                    .bold()
                    .font(.subheadline)
                    .foregroundColor(.accentColor)

                Spacer()

                Text("3D")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            }

            Text("今週鍛えた部位")
                .font(.headline)

            Text("ドラッグで回転できます")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            MuscleHeatMap3DView()
        }
        .padding([.top, .bottom], 8)
    }
}

// MARK: - Preview

#if DEBUG
struct MuscleHeatMap3DView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MuscleHeatMap3DCell()
                .mockEnvironment(weightUnit: .metric)
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}
#endif
