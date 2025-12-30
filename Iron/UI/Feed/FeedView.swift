//
//  FeedView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import Combine
import WorkoutDataKit

struct FeedView : View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject private var pinnedChartsStore = PinnedChartsStore.shared
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case pinnedChartSelector
        case pinnedChartEditor
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .pinnedChartSelector:
            return PinnedChartSelectorSheet(exercises: self.exerciseStore.shownExercises) { pinnedChart in
                self.pinnedChartsStore.pinnedCharts.append(pinnedChart)
            }
            .environmentObject(self.pinnedChartsStore)
            .typeErased
        case .pinnedChartEditor:
            return PinnedChartEditSheet()
                .environmentObject(pinnedChartsStore)
                .environmentObject(exerciseStore)
                .typeErased
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ActivityCalendarViewCell()
                }

                Section {
                    ActivityWorkoutsPerWeekCell()
                }

                Section {
                    ActivitySummaryLast7DaysCell()
                }

                Section {
                    VolumeStatsCell()
                }

                Section {
                    ProgressiveOverloadCell()
                }

                Section {
                    MuscleHeatMap3DCell()
                }

                Section {
                    EpicMilestonesCell()
                }

                ForEach(pinnedChartsStore.pinnedCharts, id: \.self) { chart in
                    if let exercise = self.exerciseStore.find(with: chart.exerciseUuid) {
                        Section {
                            ExerciseChartViewCell(exercise: exercise, measurementType: chart.measurementType)
                        }
                    }
                }
                
                Button(action: {
                    activeSheet = .pinnedChartSelector
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .accessibilityHidden(true)
                        Text("チャートを固定")
                    }
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .navigationBarTitle(Text("ホーム"))
            .navigationBarItems(trailing: Button("編集") { activeSheet = .pinnedChartEditor })
            .sheet(item: $activeSheet) { type in
                sheetView(type: type)
            }
        }
    }
}

private struct PinnedChartEditSheet: View {
    @EnvironmentObject var pinnedChartsStore: PinnedChartsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "チャート編集", leading: Button("閉じる") { self.presentationMode.wrappedValue.dismiss() }, trailing: EmptyView()).padding()
            
            Divider()
            
            List {
                ForEach(pinnedChartsStore.pinnedCharts, id: \.self) { chart in
                    Text((exerciseStore.find(with: chart.exerciseUuid)?.title ?? "不明な種目") + " (\(chart.measurementType.title))")
                }
                .onDelete { offsets in
                    self.pinnedChartsStore.pinnedCharts.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    self.pinnedChartsStore.pinnedCharts.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .placeholder(show: pinnedChartsStore.pinnedCharts.isEmpty,
                         VStack {
                            Spacer()

                            Text("固定したチャートはありません")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding()

                            Spacer()
                         }
            )
        }
        .environment(\.editMode, .constant(.active))
    }
}

private struct PinnedChartSelectorSheet: View {
    @EnvironmentObject var pinnedChartsStore: PinnedChartsStore
    
    @Environment(\.presentationMode) var presentationMode

    let onSelection: (PinnedChart) -> Void
    
    @State private var selectedExercise: Exercise? = nil

    @ObservedObject private var filter: ExerciseGroupFilter
    
    init(exercises: [Exercise], onSelection: @escaping (PinnedChart) -> Void) {
        filter = ExerciseGroupFilter(exerciseGroups: ExerciseStore.splitIntoMuscleGroups(exercises: exercises))
        self.onSelection = onSelection
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.filter.filter = ""
    }
    
    private var availableMeasurementTypes: [WorkoutExerciseChartData.MeasurementType] {
        guard let exercise = selectedExercise else { return [] }
        return WorkoutExerciseChartData.MeasurementType.allCases.filter { measurementType in
            let pinnedChart = PinnedChart(exerciseUuid: exercise.uuid, measurementType: measurementType)
            return !pinnedChartsStore.pinnedCharts.contains(pinnedChart)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SheetBar(title: "チャートを固定", leading: Button("キャンセル") { self.resetAndDismiss() }, trailing: EmptyView())
                TextField("検索", text: $filter.filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                    .padding(.top)
            }.padding()

            Divider()

            ExerciseSingleSelectionView(exerciseGroups: filter.exerciseGroups) { exercise in
                self.selectedExercise = exercise
            }
        }
        .confirmationDialog(selectedExercise?.title ?? "", isPresented: Binding(
            get: { selectedExercise != nil },
            set: { if !$0 { selectedExercise = nil } }
        ), titleVisibility: .visible) {
            ForEach(availableMeasurementTypes, id: \.self) { measurementType in
                Button(measurementType.title) {
                    guard let exercise = selectedExercise else { return }
                    let pinnedChart = PinnedChart(exerciseUuid: exercise.uuid, measurementType: measurementType)
                    self.onSelection(pinnedChart)
                    self.resetAndDismiss()
                }
            }
            Button("キャンセル", role: .cancel) {
                selectedExercise = nil
            }
        }
    }
}

#if DEBUG
struct FeedView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            FeedView()
                .mockEnvironment(weightUnit: .metric)
        }
    }
}
#endif
