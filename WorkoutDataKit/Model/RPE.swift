//
//  RPE.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public enum RPE {
    public static let allowedValues = stride(from: 7, through: 10, by: 0.5)
    
    public static func title(_ rpe: Double) -> String? {
        switch rpe {
        case 7:
            return "あと3回できた"
        case 7.5:
            return "あと2〜3回できた"
        case 8:
            return "あと2回できた"
        case 8.5:
            return "あと1〜2回できた"
        case 9:
            return "あと1回できた"
        case 9.5:
            return "もうできなかったが、重量は増やせたかも"
        case 10:
            return "限界まで追い込んだ"
        default:
            return nil
        }
    }
}
