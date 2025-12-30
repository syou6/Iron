//
//  ExerciseDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct ExerciseDetailView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    var exercise: Exercise
    
    @State private var showOptionsMenu = false
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case statistics
        case history
        case editExercise
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .history:
            return exerciseHistorySheet.typeErased
        case .statistics:
            return exerciseStatisticsSheet.typeErased
        case .editExercise:
            return EditCustomExerciseSheet(exercise: exercise)
                .environmentObject(self.exerciseStore)
                .typeErased
        }
    }
    
    private func pdfToImage(url: URL, fit: CGSize) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let scale = min(fit.width / pageRect.width, fit.height / pageRect.height)
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            // flip
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            
            // aspect fit
            ctx.cgContext.scaleBy(x: scale, y: scale)
            
            // draw
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }

    private func exerciseImages(width: CGFloat, height: CGFloat) -> [UIImage] {
        exercise.pdfPaths
            .map { ExerciseStore.defaultBuiltInExercisesResourceURL.appendingPathComponent($0) }
            .compactMap { pdfToImage(url: $0, fit: CGSize(width: width, height: height)) }
            .compactMap { $0.tinted(with: .label) }
    }
    
    private func imageHeight(geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, (geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom) * 0.7)
    }
    
    private var closeSheetButton: some View {
        Button("閉じる") {
            self.activeSheet = nil
        }
    }

    private var exerciseHistorySheet: some View {
        NavigationStack {
            ExerciseHistoryView(exercise: self.exercise)
                .navigationBarTitle("履歴", displayMode: .inline)
                .navigationBarItems(leading: closeSheetButton)
                .environmentObject(self.settingsStore)
                .environment(\.managedObjectContext, self.managedObjectContext)
        }
        
    }
    
    private var exerciseStatisticsSheet: some View {
        NavigationStack {
            ExerciseStatisticsView(exercise: self.exercise)
                .navigationBarTitle("統計", displayMode: .inline)
                .navigationBarItems(leading: closeSheetButton)
                .environmentObject(self.settingsStore)
                .environment(\.managedObjectContext, self.managedObjectContext)
        }
        
    }
    
    private func imageSection(geometry: GeometryProxy) -> some View {
        Section {
            AnimatedImageView(uiImages: self.exerciseImages(width: geometry.size.width, height: self.imageHeight(geometry: geometry)), duration: 2)
                .frame(height: self.imageHeight(geometry: geometry))
        }
    }
    
    private var descriptionSection: some View {
        Section {
            Text(self.exercise.description!)
                .lineLimit(nil)
        }
    }
    
    private var muscleSection: some View {
        Section(header: Text("筋肉".uppercased())) {
            ForEach(self.exercise.primaryMuscleCommonName, id: \.hashValue) { primaryMuscle in
                HStack {
                    Text(primaryMuscle.capitalized)
                    Spacer()
                    Text("主要")
                        .foregroundColor(.secondary)
                }
            }
            ForEach(self.exercise.secondaryMuscleCommonName, id: \.hashValue) { secondaryMuscle in
                HStack {
                    Text(secondaryMuscle.capitalized)
                    Spacer()
                    Text("補助")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var stepsSection: some View {
        Section(header: Text("手順".uppercased())) {
            ForEach(self.exercise.steps, id: \.hashValue) { step in
                Text(step as String)
                    .lineLimit(nil)
            }
        }
    }
    
    private var tipsSection: some View {
        Section(header: Text("ヒント".uppercased())) {
            ForEach(self.exercise.tips, id: \.hashValue) { tip in
                Text(tip as String)
                    .lineLimit(nil)
            }
        }
    }
    
    private var referencesSection: some View {
        Section(header: Text("参考".uppercased())) {
            ForEach(self.exercise.references, id: \.hashValue) { reference in
                Button(reference as String) {
                    if let url = URL(string: reference) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
    
    private var aliasSection: some View {
        Section(header: Text("別名".uppercased())) {
            ForEach(self.exercise.alias, id: \.hashValue) { alias in
                Text(alias)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if !self.exercise.pdfPaths.isEmpty {
                    self.imageSection(geometry: geometry)
                }

                if self.exercise.description != nil {
                    self.descriptionSection
                }

                if !(self.exercise.primaryMuscleCommonName.isEmpty && self.exercise.secondaryMuscleCommonName.isEmpty) {
                    self.muscleSection
                }

                if !self.exercise.steps.isEmpty {
                    self.stepsSection
                }

                if !self.exercise.tips.isEmpty {
                    self.tipsSection
                }

                if !self.exercise.references.isEmpty {
                    self.referencesSection
                }

                if !self.exercise.alias.isEmpty {
                    self.aliasSection
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
        }
        .sheet(item: $activeSheet) { type in
            self.sheetView(type: type)
        }
        .confirmationDialog("種目", isPresented: $showOptionsMenu, titleVisibility: .visible) {
            Button("履歴") {
                self.activeSheet = .history
            }
            Button("統計") {
                self.activeSheet = .statistics
            }
            if exerciseStore.isHidden(exercise: exercise) {
                Button("表示") {
                    self.exerciseStore.show(exercise: self.exercise)
                }
            } else if !exercise.isCustom {
                Button("非表示") {
                    self.exerciseStore.hide(exercise: self.exercise)
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .navigationBarTitle(Text(exercise.title), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                Button(action: {
                    self.showOptionsMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .padding([.leading, .top, .bottom])
                }
                .accessibilityLabel("オプション")
                .accessibilityHint("履歴、統計などを表示")
                if exercise.isCustom {
                    Button("編集") {
                        self.activeSheet = .editExercise
                    }
                }
            }
        )
    }
}

#if DEBUG
struct ExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ExerciseDetailView(exercise: ExerciseStore.shared.exercises.first(where: { $0.everkineticId == 99 })!)
                .mockEnvironment(weightUnit: .metric)
        }
    }
}
#endif
