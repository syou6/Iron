//
//  SettingsStore.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 16.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var weightUnit: WeightUnit {
        get {
            userDefaults.weightUnit
        }
        set {
            self.objectWillChange.send()
            userDefaults.weightUnit = newValue
        }
    }
    
    var defaultRestTime: TimeInterval {
        get {
            userDefaults.defaultRestTime
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTime = newValue
        }
    }
    
    var defaultRestTimeDumbbellBased: TimeInterval {
        get {
            userDefaults.defaultRestTimeDumbbellBased
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTimeDumbbellBased = newValue
        }
    }
    
    var defaultRestTimeBarbellBased: TimeInterval {
        get {
            userDefaults.defaultRestTimeBarbellBased
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTimeBarbellBased = newValue
        }
    }
    
    var keepRestTimerRunning: Bool {
        get {
            userDefaults.keepRestTimerRunning
        }
        set {
            self.objectWillChange.send()
            userDefaults.keepRestTimerRunning = newValue
        }
    }

    var autoStartRestTimer: Bool {
        get {
            userDefaults.autoStartRestTimer
        }
        set {
            self.objectWillChange.send()
            userDefaults.autoStartRestTimer = newValue
        }
    }

    var maxRepetitionsOneRepMax: Int {
        get {
            userDefaults.maxRepetitionsOneRepMax
        }
        set {
            self.objectWillChange.send()
            userDefaults.maxRepetitionsOneRepMax = newValue
        }
    }
    
    var autoBackup: Bool {
        get {
            userDefaults.autoBackup
        }
        set {
            self.objectWillChange.send()
            userDefaults.autoBackup = newValue
        }
    }
    
    var watchCompanion: Bool {
        get {
            userDefaults.watchCompanion
        }
        set {
            self.objectWillChange.send()
            userDefaults.watchCompanion = newValue
        }
    }

    var defaultWeight: Double {
        get {
            userDefaults.defaultWeight
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultWeight = newValue
        }
    }

    var defaultRepetitions: Int {
        get {
            userDefaults.defaultRepetitions
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRepetitions = newValue
        }
    }

    var autoFillLastRecord: Bool {
        get {
            userDefaults.autoFillLastRecord
        }
        set {
            self.objectWillChange.send()
            userDefaults.autoFillLastRecord = newValue
        }
    }
}

#if DEBUG
extension SettingsStore {
    static let mockMetric: SettingsStore = {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_metric")!)
        store.weightUnit = .metric
        return store
    }()

    static let mockImperial: SettingsStore = {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_imperial")!)
        store.weightUnit = .imperial
        return store
    }()
}
#endif
