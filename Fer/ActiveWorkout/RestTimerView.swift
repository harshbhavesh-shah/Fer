//
//  RestTimerView.swift
//  Fer
//
//  Floating rest-timer bar shown at the bottom of the active workout screen.
//

import SwiftUI

struct RestTimerBar: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    private var progress: Double {
        guard viewModel.restTotal > 0 else { return 0 }
        return Double(viewModel.restTotal - viewModel.restRemaining) / Double(viewModel.restTotal)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                Text("\(viewModel.restRemaining)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Resting").font(.subheadline.weight(.semibold))
                Text("Next set coming up").font(.caption).opacity(0.85)
            }
            .foregroundStyle(.white)

            Spacer()

            Button {
                viewModel.addRestTime(15)
            } label: {
                Text("+15s")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }

            Button {
                viewModel.skipRest()
            } label: {
                Image(systemName: "forward.fill")
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(Theme.gradient(for: .indigo))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
