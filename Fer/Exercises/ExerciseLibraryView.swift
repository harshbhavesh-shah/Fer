//
//  ExerciseLibraryView.swift
//  Fer
//

import SwiftUI
import Charts

struct ExerciseLibraryView: View {
    @ObservedObject var historyVM: HistoryViewModel
    @State private var search = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var appeared = false

    private var filtered: [Exercise] {
        ExerciseLibrary.all.filter { exercise in
            let matchesSearch = search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search)
            let matchesMuscle = selectedMuscle == nil || exercise.primaryMuscle == selectedMuscle
            return matchesSearch && matchesMuscle
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !historyVM.volumeByMuscleGroup().isEmpty && search.isEmpty {
                MuscleBreakdownCard(historyVM: historyVM)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedMuscle == nil) {
                        Haptics.selection()
                        withAnimation { selectedMuscle = nil }
                    }
                    ForEach(MuscleGroup.allCases) { muscle in
                        FilterChip(title: muscle.displayName, isSelected: selectedMuscle == muscle) {
                            Haptics.selection()
                            withAnimation { selectedMuscle = muscle }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            List(filtered) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise, historyVM: historyVM)
                } label: {
                    HStack {
                        Image(systemName: exercise.primaryMuscle.icon)
                            .foregroundStyle(exercise.primaryMuscle.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                            Text(exercise.primaryMuscle.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
        }
        .searchable(text: $search, prompt: "Search exercises")
        .navigationTitle("Exercises")
    }
}

private struct MuscleBreakdownCard: View {
    @ObservedObject var historyVM: HistoryViewModel

    private var breakdown: [(muscle: MuscleGroup, volume: Double)] {
        Array(historyVM.volumeByMuscleGroup().prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume by Muscle Group").font(.headline)
            HStack(spacing: 16) {
                Chart(breakdown, id: \.muscle) { entry in
                    SectorMark(
                        angle: .value("Volume", entry.volume),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(entry.muscle.accentColor)
                    .cornerRadius(3)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(breakdown, id: \.muscle) { entry in
                        HStack(spacing: 6) {
                            Circle().fill(entry.muscle.accentColor).frame(width: 8, height: 8)
                            Text(entry.muscle.displayName).font(.caption)
                            Spacer()
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}
