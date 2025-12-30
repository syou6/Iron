//
//  WorkoutSetTag.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public enum WorkoutSetTag: String, CaseIterable {
//    case warmUp // disable for now, see if there is a need for this
    case dropSet
    case failure
    
    public var title: String {
        switch self {
//        case .warmUp:
//            return "ウォームアップ"
        case .dropSet:
            return "ドロップセット"
        case .failure:
            return "失敗"
        }
    }
}
