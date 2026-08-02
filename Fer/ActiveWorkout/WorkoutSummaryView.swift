//
//  WorkoutSummaryView.swift
//  Fer
//
//  Celebration screen shown when finishing an active workout.
//

import SwiftUI

struct WorkoutFinishSummaryView: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    let onConfirm: () -> Void
    @State private var celebrate = false
    @State private var isSaving = false
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .scaleEffect(celebrate ? 1.0 : 0.4)
                .opacity(celebrate ? 1 : 0)
                .symbolEffect(.bounce, value: celebrate)

            Text("Workout Complete!")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            HStack(spacing: 24) {
                SummaryStat(value: "\(viewModel.totalSetsCompleted)", label: "Sets")
                SummaryStat(value: Formatters.weight(viewModel.totalVolume, unit: settings.weightUnit), label: "Volume (\(settings.weightUnit.label))")
                SummaryStat(value: Formatters.duration(viewModel.elapsed), label: "Duration")
            }
            .opacity(celebrate ? 1 : 0)
            .offset(y: celebrate ? 0 : 16)

            Spacer()

            Button {
                isSaving = true
                Haptics.success()
                onConfirm()
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save & Finish")
                }
            }
            .buttonStyle(.primaryAction(color: .green))
            .disabled(isSaving)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                celebrate = true
            }
            Haptics.success()
        }
    }
}

private struct SummaryStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
