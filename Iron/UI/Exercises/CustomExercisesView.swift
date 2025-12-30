//
//  CustomExercisesView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct CustomExercisesView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case createCustomExercise
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .createCustomExercise:
            return CreateCustomExerciseSheet()
                .environmentObject(exerciseStore)
                .typeErased
        }
    }
    
    @State private var offsetsToDelete: IndexSet?
    
    private func deleteAtOffsets(offsets: IndexSet) {
        for i in offsets {
            assert(self.exerciseStore.customExercises[i].isCustom)
            let uuid = self.exerciseStore.customExercises[i].uuid
            self.deleteWorkoutExercises(with: uuid)
            self.exerciseStore.deleteCustomExercise(with: uuid)
        }
        self.managedObjectContext.saveOrCrash()
    }
    
    var body: some View {
        List {
            ForEach(exerciseStore.customExercises, id: \.id) { exercise in
                NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise)
                    .environmentObject(self.settingsStore))
            }
            .onDelete { offsets in
                self.offsetsToDelete = offsets
            }
            Button(action: {
                self.activeSheet = .createCustomExercise
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("種目を作成")
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationBarItems(trailing: EditButton())
        .sheet(item: $activeSheet, content: { type in
            self.sheetView(type: type)
        })
        .confirmationDialog("この操作は取り消せません", isPresented: Binding(
            get: { offsetsToDelete != nil },
            set: { if !$0 { offsetsToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                if let offsets = offsetsToDelete {
                    self.deleteAtOffsets(offsets: offsets)
                }
            }
            Button("キャンセル", role: .cancel) {
                offsetsToDelete = nil
            }
        } message: {
            Text("警告: この種目に属するセットも削除されます")
        }
    }
    
    private func deleteWorkoutExercises(with uuid: UUID) {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.exerciseUuid)) == %@", uuid as CVarArg)
        guard let workoutExercises = try? managedObjectContext.fetch(request) else { return }
        workoutExercises.forEach { managedObjectContext.delete($0) }
    }
}

#if DEBUG
struct CustomExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomExercisesView()
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
