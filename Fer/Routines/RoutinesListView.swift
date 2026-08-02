//
//  RoutinesListView.swift
//  Fer
//

import SwiftUI

struct RoutinesListView: View {
    @ObservedObject var viewModel: RoutinesViewModel
    @Binding var activeWorkout: WorkoutSessionViewModel?
    @State private var showingEditor = false
    @State private var editingRoutine: RoutineTemplate?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.routines) { routine in
                    RoutineCard(routine: routine) {
                        guard activeWorkout == nil else { Haptics.warning(); return }
                        Haptics.medium()
                        viewModel.markUsed(routine)
                        activeWorkout = WorkoutSessionViewModel(from: routine)
                    } onEdit: {
                        editingRoutine = routine
                    } onDelete: {
                        withAnimation { viewModel.delete(routine) }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }

                if viewModel.routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routines yet",
                        message: "Create a routine template so you can start a workout in one tap."
                    )
                    .padding(.top, 60)
                }
            }
            .padding()
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.routines)
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    editingRoutine = RoutineTemplate(name: "New Routine", exercises: [])
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineEditorView(viewModel: viewModel, routine: routine)
        }
    }
}

private struct RoutineCard: View {
    let routine: RoutineTemplate
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: routine.iconName)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name).font(.headline)
                    Text("\(routine.exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if !routine.exercises.isEmpty {
                Text(routine.exercises.map(\.exerciseName).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Button(action: onStart) {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryAction())
        }
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
