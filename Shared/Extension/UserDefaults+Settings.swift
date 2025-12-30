//
//  UserDefaults+Settings.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum SettingsKeys: String, CaseIterable {
        case weightUnit
        case defaultRestTime
        case defaultRestTimeDumbbellBased
        case defaultRestTimeBarbellBased
        case keepRestTimerRunning
        case autoStartRestTimer
        case maxRepetitionsOneRepMax
        case autoBackup
        case watchCompanion
        case defaultWeight
        case defaultRepetitions
        case autoFillLastRecord
    }

    var weightUnit: WeightUnit {
        set {
            self.set(newValue.rawValue, forKey: SettingsKeys.weightUnit.rawValue)
        }
        get {
            let weightUnit = WeightUnit(rawValue: self.string(forKey: SettingsKeys.weightUnit.rawValue) ?? "")
            if let weightUnit = weightUnit {
                return weightUnit
            } else {
                let fallback = Locale.current.usesMetricSystem ? WeightUnit.metric : WeightUnit.imperial
                self.weightUnit = fallback // safe the new weight unit
                return fallback
            }
        }
    }
    
    var defaultRestTime: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTime.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTime.rawValue) as? TimeInterval ?? 90 // default 1:30
        }
    }
    
    var defaultRestTimeDumbbellBased: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTimeDumbbellBased.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTimeDumbbellBased.rawValue) as? TimeInterval ?? 150 // default 2:30
        }
    }
    
    var defaultRestTimeBarbellBased: TimeInterval {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRestTimeBarbellBased.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRestTimeBarbellBased.rawValue) as? TimeInterval ?? 180 // default 3:00
        }
    }
    
    var keepRestTimerRunning: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.keepRestTimerRunning.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.keepRestTimerRunning.rawValue) as? Bool ?? true // default true
        }
    }

    var autoStartRestTimer: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.autoStartRestTimer.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.autoStartRestTimer.rawValue) as? Bool ?? true // default true
        }
    }

    var maxRepetitionsOneRepMax: Int {
        set {
            self.set(newValue, forKey: SettingsKeys.maxRepetitionsOneRepMax.rawValue)
        }
        get {
            (self.value(forKey: SettingsKeys.maxRepetitionsOneRepMax.rawValue) as? Int)?.clamped(to: maxRepetitionsOneRepMaxValues) ?? 5 // default 5
        }
    }
    
    var autoBackup: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.autoBackup.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.autoBackup.rawValue) as? Bool ?? false // default false
        }
    }
    
    var watchCompanion: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.watchCompanion.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.watchCompanion.rawValue) as? Bool ?? true // default true
        }
    }

    var defaultWeight: Double {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultWeight.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultWeight.rawValue) as? Double ?? 20.0 // default 20kg
        }
    }

    var defaultRepetitions: Int {
        set {
            self.set(newValue, forKey: SettingsKeys.defaultRepetitions.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.defaultRepetitions.rawValue) as? Int ?? 10 // default 10 reps
        }
    }

    var autoFillLastRecord: Bool {
        set {
            self.set(newValue, forKey: SettingsKeys.autoFillLastRecord.rawValue)
        }
        get {
            self.value(forKey: SettingsKeys.autoFillLastRecord.rawValue) as? Bool ?? true // default true
        }
    }
}

let maxRepetitionsOneRepMaxValues = 1...10
let defaultWeightValues: [Double] = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100]
let defaultRepetitionsValues = 1...20
