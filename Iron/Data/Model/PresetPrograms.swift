//
//  PresetPrograms.swift
//  Iron
//
//  Created for Nan Ton? app
//

import Foundation

struct PresetProgram: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let routines: [PresetRoutine]
}

struct PresetRoutine {
    let name: String
    let exercises: [PresetExercise]
}

struct PresetExercise {
    let everkineticId: Int
    let sets: Int
    let reps: Int
}

enum PresetPrograms {
    static let allPrograms: [PresetProgram] = [
        ppl,
        strongLifts5x5,
        upperLower,
        fullBody
    ]

    // Push Pull Legs
    static let ppl = PresetProgram(
        name: "PPL (Push/Pull/Legs)",
        description: "週6日のプッシュ・プル・レッグスプログラム",
        routines: [
            PresetRoutine(name: "Push A", exercises: [
                PresetExercise(everkineticId: 42, sets: 4, reps: 6),   // Barbell Bench Press
                PresetExercise(everkineticId: 1, sets: 3, reps: 10),   // Overhead Press
                PresetExercise(everkineticId: 97, sets: 3, reps: 10),  // Incline Dumbbell Press
                PresetExercise(everkineticId: 178, sets: 3, reps: 12), // Tricep Pushdown
                PresetExercise(everkineticId: 104, sets: 3, reps: 15)  // Lateral Raise
            ]),
            PresetRoutine(name: "Pull A", exercises: [
                PresetExercise(everkineticId: 36, sets: 4, reps: 6),   // Barbell Row
                PresetExercise(everkineticId: 185, sets: 3, reps: 8),  // Pull-up
                PresetExercise(everkineticId: 115, sets: 3, reps: 10), // One Arm Dumbbell Row
                PresetExercise(everkineticId: 53, sets: 3, reps: 12),  // Face Pull
                PresetExercise(everkineticId: 37, sets: 3, reps: 12)   // Barbell Curl
            ]),
            PresetRoutine(name: "Legs A", exercises: [
                PresetExercise(everkineticId: 99, sets: 4, reps: 6),   // Barbell Squat
                PresetExercise(everkineticId: 191, sets: 3, reps: 8),  // Romanian Deadlift
                PresetExercise(everkineticId: 106, sets: 3, reps: 10), // Leg Press
                PresetExercise(everkineticId: 107, sets: 3, reps: 12), // Leg Curl
                PresetExercise(everkineticId: 55, sets: 4, reps: 15)   // Calf Raise
            ]),
            PresetRoutine(name: "Push B", exercises: [
                PresetExercise(everkineticId: 1, sets: 4, reps: 6),    // Overhead Press
                PresetExercise(everkineticId: 42, sets: 3, reps: 10),  // Barbell Bench Press
                PresetExercise(everkineticId: 61, sets: 3, reps: 10),  // Dumbbell Fly
                PresetExercise(everkineticId: 178, sets: 3, reps: 12), // Tricep Pushdown
                PresetExercise(everkineticId: 104, sets: 3, reps: 15)  // Lateral Raise
            ]),
            PresetRoutine(name: "Pull B", exercises: [
                PresetExercise(everkineticId: 185, sets: 4, reps: 6),  // Pull-up
                PresetExercise(everkineticId: 36, sets: 3, reps: 10),  // Barbell Row
                PresetExercise(everkineticId: 53, sets: 3, reps: 10),  // Face Pull
                PresetExercise(everkineticId: 91, sets: 3, reps: 12),  // Hammer Curl
                PresetExercise(everkineticId: 49, sets: 3, reps: 15)   // Dumbbell Shrug
            ]),
            PresetRoutine(name: "Legs B", exercises: [
                PresetExercise(everkineticId: 28, sets: 4, reps: 5),   // Deadlift
                PresetExercise(everkineticId: 99, sets: 3, reps: 8),   // Barbell Squat
                PresetExercise(everkineticId: 107, sets: 3, reps: 10), // Leg Curl
                PresetExercise(everkineticId: 125, sets: 3, reps: 10), // Walking Lunge
                PresetExercise(everkineticId: 55, sets: 4, reps: 15)   // Calf Raise
            ])
        ]
    )

    // StrongLifts 5x5
    static let strongLifts5x5 = PresetProgram(
        name: "StrongLifts 5x5",
        description: "初心者向けの基本的な全身プログラム",
        routines: [
            PresetRoutine(name: "Workout A", exercises: [
                PresetExercise(everkineticId: 99, sets: 5, reps: 5),   // Barbell Squat
                PresetExercise(everkineticId: 42, sets: 5, reps: 5),   // Barbell Bench Press
                PresetExercise(everkineticId: 36, sets: 5, reps: 5)    // Barbell Row
            ]),
            PresetRoutine(name: "Workout B", exercises: [
                PresetExercise(everkineticId: 99, sets: 5, reps: 5),   // Barbell Squat
                PresetExercise(everkineticId: 1, sets: 5, reps: 5),    // Overhead Press
                PresetExercise(everkineticId: 28, sets: 1, reps: 5)    // Deadlift
            ])
        ]
    )

    // Upper Lower Split
    static let upperLower = PresetProgram(
        name: "Upper/Lower Split",
        description: "週4日の上半身・下半身分割プログラム",
        routines: [
            PresetRoutine(name: "Upper A", exercises: [
                PresetExercise(everkineticId: 42, sets: 4, reps: 6),   // Barbell Bench Press
                PresetExercise(everkineticId: 36, sets: 4, reps: 6),   // Barbell Row
                PresetExercise(everkineticId: 1, sets: 3, reps: 8),    // Overhead Press
                PresetExercise(everkineticId: 185, sets: 3, reps: 8),  // Pull-up
                PresetExercise(everkineticId: 37, sets: 3, reps: 12)   // Barbell Curl
            ]),
            PresetRoutine(name: "Lower A", exercises: [
                PresetExercise(everkineticId: 99, sets: 4, reps: 5),   // Barbell Squat
                PresetExercise(everkineticId: 191, sets: 4, reps: 8),  // Romanian Deadlift
                PresetExercise(everkineticId: 106, sets: 3, reps: 10), // Leg Press
                PresetExercise(everkineticId: 107, sets: 3, reps: 12), // Leg Curl
                PresetExercise(everkineticId: 55, sets: 4, reps: 15)   // Calf Raise
            ]),
            PresetRoutine(name: "Upper B", exercises: [
                PresetExercise(everkineticId: 97, sets: 4, reps: 8),   // Incline Dumbbell Press
                PresetExercise(everkineticId: 115, sets: 4, reps: 8),  // One Arm Dumbbell Row
                PresetExercise(everkineticId: 104, sets: 3, reps: 12), // Lateral Raise
                PresetExercise(everkineticId: 53, sets: 3, reps: 15),  // Face Pull
                PresetExercise(everkineticId: 178, sets: 3, reps: 12)  // Tricep Pushdown
            ]),
            PresetRoutine(name: "Lower B", exercises: [
                PresetExercise(everkineticId: 28, sets: 4, reps: 5),   // Deadlift
                PresetExercise(everkineticId: 99, sets: 3, reps: 8),   // Barbell Squat
                PresetExercise(everkineticId: 125, sets: 3, reps: 10), // Walking Lunge
                PresetExercise(everkineticId: 107, sets: 3, reps: 10), // Leg Curl
                PresetExercise(everkineticId: 55, sets: 4, reps: 15)   // Calf Raise
            ])
        ]
    )

    // Full Body
    static let fullBody = PresetProgram(
        name: "Full Body 3x",
        description: "週3日の全身トレーニングプログラム",
        routines: [
            PresetRoutine(name: "Day 1", exercises: [
                PresetExercise(everkineticId: 99, sets: 4, reps: 5),   // Barbell Squat
                PresetExercise(everkineticId: 42, sets: 4, reps: 6),   // Barbell Bench Press
                PresetExercise(everkineticId: 36, sets: 4, reps: 6),   // Barbell Row
                PresetExercise(everkineticId: 104, sets: 3, reps: 12), // Lateral Raise
                PresetExercise(everkineticId: 37, sets: 3, reps: 12)   // Barbell Curl
            ]),
            PresetRoutine(name: "Day 2", exercises: [
                PresetExercise(everkineticId: 28, sets: 4, reps: 5),   // Deadlift
                PresetExercise(everkineticId: 1, sets: 4, reps: 6),    // Overhead Press
                PresetExercise(everkineticId: 185, sets: 4, reps: 8),  // Pull-up
                PresetExercise(everkineticId: 61, sets: 3, reps: 10),  // Dumbbell Fly
                PresetExercise(everkineticId: 178, sets: 3, reps: 12)  // Tricep Pushdown
            ]),
            PresetRoutine(name: "Day 3", exercises: [
                PresetExercise(everkineticId: 99, sets: 4, reps: 6),   // Barbell Squat
                PresetExercise(everkineticId: 97, sets: 4, reps: 8),   // Incline Dumbbell Press
                PresetExercise(everkineticId: 115, sets: 4, reps: 8),  // One Arm Dumbbell Row
                PresetExercise(everkineticId: 53, sets: 3, reps: 15),  // Face Pull
                PresetExercise(everkineticId: 55, sets: 4, reps: 15)   // Calf Raise
            ])
        ]
    )
}
