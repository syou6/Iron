//
//  Exercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public struct Exercise: Hashable {
    public let uuid: UUID // we use this for actually identifying the exercise
    public let everkineticId: Int // this is the everkinetic exercise id or 10000 if it's a custom exercise
    public let title: String
    public let alias: [String]
    public let description: String? // primer
    public let primaryMuscle: [String] // primary
    public let secondaryMuscle: [String] // secondary
    public let equipment: [String]
    public let steps: [String]
    public let tips: [String]
    public let references: [String]
    public let pdfPaths: [String]
}

// MARK: - Muscle Names
extension Exercise {
    public var primaryMuscleCommonName: [String] {
        primaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    public var secondaryMuscleCommonName: [String] {
        secondaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    public var muscleGroup: String {
        guard let muscle = primaryMuscle.first else { return "other" }
        return Self.muscleGroup(for: muscle) ?? "other"
    }
    
    public static var muscleNames: [String] {
        commonMuscleNames.keys.map { $0 }
    }
    
    public static func commonMuscleName(for muscle: String) -> String? {
        commonMuscleNames[muscle]
    }
    
    public static func muscleGroup(for muscle: String) -> String? {
        muscleGroupNames[muscle]
    }
    
    private static var commonMuscleNames: [String : String] = [
        "abdominals": "腹筋",
        "biceps brachii": "上腕二頭筋",
        "deltoid": "肩",
        "erector spinae": "脊柱起立筋",
        "gastrocnemius": "ふくらはぎ",
        "soleus": "ふくらはぎ",
        "glutaeus maximus": "臀筋",
        "ischiocrural muscles": "ハムストリング",
        "latissimus dorsi": "広背筋",
        "obliques": "腹斜筋",
        "pectoralis major": "胸",
        "quadriceps": "大腿四頭筋",
        "trapezius": "僧帽筋",
        "triceps brachii": "上腕三頭筋"
    ]
    
    private static var muscleGroupNames: [String : String] = [
        // 腹筋
        "abdominals": "腹筋",
        "obliques": "腹筋",
        // 腕
        "biceps brachii": "腕",
        "triceps brachii": "腕",
        // 肩
        "deltoid": "肩",
        // 背中
        "erector spinae": "背中",
        "latissimus dorsi": "背中",
        "trapezius": "背中",
        // 脚
        "gastrocnemius": "脚",
        "soleus": "脚",
        "glutaeus maximus": "脚",
        "ischiocrural muscles": "脚",
        "quadriceps": "脚",
        // 胸
        "pectoralis major": "胸"
    ]
}

// MARK: - Exercise Type
extension Exercise {
    public enum ExerciseType: CaseIterable {
        case barbell
        case dumbbell
        case other
        
        public var title: String {
            switch self {
            case .barbell:
                return "バーベル"
            case .dumbbell:
                return "ダンベル"
            case .other:
                return "その他"
            }
        }
        
        var equipment: String? {
            switch self {
            case .barbell:
                return "barbell"
            case .dumbbell:
                return "dumbbell"
            case .other:
                return nil
            }
        }
    }
    
    public var type: ExerciseType {
        ExerciseType.allCases.first { $0.equipment.map { equipment.contains($0) } ?? false } ?? .other
    }
}

// MARK: - Custom Exercise
extension Exercise {
    static let customEverkineticId = 10000
    
    private static func isCustom(everkineticId: Int) -> Bool {
        everkineticId >= Exercise.customEverkineticId
    }
    
    public var isCustom: Bool {
        Self.isCustom(everkineticId: everkineticId)
    }
}

// MARK: - Codable
extension Exercise: Codable {
    private enum CodingKeys: String, CodingKey {
        case uuid
        case id
//        case name
        case title
        case alias
        case primer
//        case type
        case primary
        case secondary
        case equipment
        case steps
        case tips
        case references
        case pdf
//        case png
    }
    
    // MARK: Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let id = try container.decode(Int.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let alias = try container.decodeIfPresent([String].self, forKey: .alias) ?? []
        let primer = try container.decodeIfPresent(String.self, forKey: .primer)
        let primary = try container.decode([String].self, forKey: .primary)
        let secondary = try container.decode([String].self, forKey: .secondary)
        let equipment = try container.decode([String].self, forKey: .equipment)
        let steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        let tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        let references = try container.decodeIfPresent([String].self, forKey: .references) ?? []
        let pdf = try container.decodeIfPresent([String].self, forKey: .pdf) ?? []
        
        self.init(uuid: uuid, everkineticId: id, title: title, alias: alias, description: primer, primaryMuscle: primary, secondaryMuscle: secondary, equipment: equipment, steps: steps, tips: tips, references: references, pdfPaths: pdf)
    }
    
    // MARK: Encodalbe
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(everkineticId, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(alias, forKey: .alias)
        try container.encodeIfPresent(description, forKey: .primer)
        try container.encode(primaryMuscle, forKey: .primary)
        try container.encode(secondaryMuscle, forKey: .secondary)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(steps, forKey: .steps)
        try container.encode(tips, forKey: .tips)
        try container.encode(references, forKey: .references)
        try container.encode(pdfPaths, forKey: .pdf)
    }
}
