//
//  ActiveWorkoutView.swift
//  Fer
//
//  Deliberately matches Hevy's active-workout screen closely (including
//  forcing dark mode regardless of system setting) — see the two reference
//  screenshots this was built from. Two elements are substituted rather
//  than pixel-matched since we don't have Hevy's art assets: the body
//  silhouette becomes a row of muscle-group icons, and per-exercise photo
//  thumbnails become a muscle-group icon badge — both reuse Fer's existing
//  MuscleGroup taxonomy.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    @Binding var activeWorkout: WorkoutSessionViewModel?
    @ObservedObject var historyVM: HistoryViewModel
    let onMinimize: () -> Void

    @ObservedObject private var connectivity = PhoneConnectivityManager.shared
    @ObservedObject private var heartRate = HeartRateMonitor.shared

    @State private var showingPicker = false
    @State private var showingDiscardConfirm = false
    @State private var showingSummary = false

    var body: some View {
        workoutContent
            .preferredColorScheme(.dark)
            .onAppear { heartRate.start() }
            .onDisappear { heartRate.stop() }
    }

    private var progressFraction: Double {
        let total = viewModel.exercises.reduce(0) { $0 + $1.sets.count }
        guard total > 0 else { return 0 }
        return Double(viewModel.totalSetsCompleted) / Double(total)
    }

    private var workoutContent: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseLogCard(
                                exercise: exercise,
                                historyVM: historyVM,
                                restSeconds: viewModel.restSecondsByExerciseId[exercise.exerciseId] ?? SettingsStore.shared.defaultRestSeconds,
                                onAddSet: { viewModel.addSet(to: index) },
                                onToggleSet: { setIndex in
                                    viewModel.toggleComplete(exerciseIndex: index, setIndex: setIndex)
                                },
                                onRemoveSet: { setIndex in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.removeSet(exerciseIndex: index, setIndex: setIndex)
                                    }
                                },
                                onUpdateWeight: { setIndex, weight in
                                    viewModel.exercises[index].sets[setIndex].weight = weight
                                },
                                onUpdateReps: { setIndex, reps in
                                    viewModel.exercises[index].sets[setIndex].reps = reps
                                },
                                onToggleWarmup: { setIndex in
                                    viewModel.exercises[index].sets[setIndex].isWarmup.toggle()
                                },
                                onUpdateNotes: { notes in
                                    viewModel.exercises[index].notes = notes
                                },
                                onUpdateRestSeconds: { seconds in
                                    viewModel.restSecondsByExerciseId[exercise.exerciseId] = seconds
                                },
                                onRemoveExercise: {
                                    withAnimation { viewModel.removeExercise(at: index) }
                                }
                            )
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))

                            Divider().background(Color.white.opacity(0.08))
                        }

                        Button {
                            Haptics.light()
                            showingPicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .foregroundStyle(.white)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding()

                        if viewModel.exercises.isEmpty {
                            EmptyStateView(icon: "dumbbell", title: "Add your first exercise", message: "Tap below to pick something from the library.")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, viewModel.isResting ? 100 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.exercises)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if viewModel.isResting {
                RestTimerBar(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                viewModel.addExercise(exercise)
            }
        }
        .sheet(isPresented: $showingSummary) {
            WorkoutFinishSummaryView(viewModel: viewModel) {
                Task {
                    await viewModel.finish()
                    activeWorkout = nil
                }
            }
            .interactiveDismissDisabled()
        }
        .confirmationDialog("Discard this workout?", isPresented: $showingDiscardConfirm, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                viewModel.discard()
                activeWorkout = nil
            }
            Button("Keep Going", role: .cancel) {}
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isResting)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                CircleIconButton(systemName: "chevron.down", action: onMinimize)

                Text("Log Workout")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Menu {
                    ForEach([30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                        Button("\(seconds)s") {
                            Haptics.selection()
                            SettingsStore.shared.defaultRestSeconds = seconds
                        }
                    }
                } label: {
                    CircleIconButton(systemName: "alarm", action: {})
                }

                Button {
                    Haptics.success()
                    showingSummary = true
                } label: {
                    Text("Finish")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                }
                .disabled(viewModel.totalSetsCompleted == 0)
                .opacity(viewModel.totalSetsCompleted == 0 ? 0.5 : 1)
                .contextMenu {
                    Button("Discard Workout", systemImage: "trash", role: .destructive) {
                        showingDiscardConfirm = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            ProgressView(value: progressFraction)
                .tint(Theme.accent)
                .frame(height: 3)
                .animation(.easeOut(duration: 0.3), value: progressFraction)

            liveSyncRow
            WorkoutStatsHeader(viewModel: viewModel)
        }
        .background(Color.black)
    }

    private var liveSyncRow: some View {
        HStack {
            Circle()
                .fill(connectivity.isWatchReachable ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(connectivity.isWatchReachable ? "Live Sync Active" : "Watch Not Connected")
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            if let bpm = heartRate.latestBPM {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("\(bpm) bpm")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
    }
}

/// At-a-glance volume/duration/sets, plus a substitute for Hevy's body
/// silhouette graphic: a small row of muscle-group icons for the exercises
/// in this session (we don't have Hevy's anatomical artwork).
private struct WorkoutStatsHeader: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    @ObservedObject private var settings = SettingsStore.shared

    private var musclesWorked: [MuscleGroup] {
        let exercisesById = Dictionary(uniqueKeysWithValues: ExerciseLibrary.all.map { ($0.id, $0) })
        var seen = Set<MuscleGroup>()
        var ordered: [MuscleGroup] = []
        for exercise in viewModel.exercises {
            guard let muscle = exercisesById[exercise.exerciseId]?.primaryMuscle, !seen.contains(muscle) else { continue }
            seen.insert(muscle)
            ordered.append(muscle)
        }
        return ordered
    }

    var body: some View {
        HStack(alignment: .center) {
            stat(value: Formatters.weight(viewModel.totalVolume, unit: settings.weightUnit), label: settings.weightUnit.label.uppercased())
            stat(value: Formatters.duration(viewModel.elapsed), label: "DURATION")
            stat(value: "\(viewModel.totalSetsCompleted)", label: "SETS")

            if !musclesWorked.isEmpty {
                HStack(spacing: -8) {
                    ForEach(musclesWorked.prefix(3)) { muscle in
                        Image(systemName: muscle.icon)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(muscle.accentColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(label == "DURATION" ? Theme.accent : .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExerciseLogCard: View {
    let exercise: LoggedExercise
    @ObservedObject var historyVM: HistoryViewModel
    let restSeconds: Int
    let onAddSet: () -> Void
    let onToggleSet: (Int) -> Void
    let onRemoveSet: (Int) -> Void
    let onUpdateWeight: (Int, Double) -> Void
    let onUpdateReps: (Int, Int) -> Void
    let onToggleWarmup: (Int) -> Void
    let onUpdateNotes: (String) -> Void
    let onUpdateRestSeconds: (Int) -> Void
    let onRemoveExercise: () -> Void

    @ObservedObject private var settings = SettingsStore.shared

    private var muscle: MuscleGroup? {
        ExerciseLibrary.all.first { $0.id == exercise.exerciseId }?.primaryMuscle
    }

    private var notesBinding: Binding<String> {
        Binding(get: { exercise.notes }, set: onUpdateNotes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: muscle?.icon ?? "dumbbell.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(muscle?.accentColor ?? .gray)
                    .clipShape(Circle())

                Text(exercise.exerciseName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.accent)

                Spacer()

                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive, action: onRemoveExercise)
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.white.opacity(0.6))
                }
            }

            TextField("Add notes here...", text: notesBinding, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .tint(Theme.accent)

            Menu {
                ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                    Button("\(seconds)s") {
                        Haptics.selection()
                        onUpdateRestSeconds(seconds)
                    }
                }
                Button("Off") {
                    Haptics.selection()
                    onUpdateRestSeconds(0)
                }
            } label: {
                Label(restSeconds > 0 ? "Rest Timer: \(restSeconds)s" : "Rest Timer: OFF", systemImage: "timer")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
            }

            HStack {
                Text("SET").frame(width: 30, alignment: .leading)
                Text("PREVIOUS").frame(width: 74, alignment: .leading)
                Text(settings.weightUnit.label.uppercased()).frame(maxWidth: .infinity, alignment: .leading)
                Text("REPS").frame(maxWidth: .infinity, alignment: .leading)
                Text("").frame(width: 36)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.4))

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                SwipeToDeleteRow(onDelete: { onRemoveSet(index) }) {
                    SetRow(
                        index: index + 1,
                        set: set,
                        previousSet: previousSet(at: index),
                        onToggle: { onToggleSet(index) },
                        onToggleWarmup: { onToggleWarmup(index) },
                        onWeightChange: { onUpdateWeight(index, $0) },
                        onRepsChange: { onUpdateReps(index, $0) }
                    )
                }
            }

            Button(action: onAddSet) {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
            .padding(.top, 4)
        }
        .padding()
    }

    /// The matching set (by index) from the most recent time this exercise
    /// was logged, so you can see what to beat without leaving the screen.
    private func previousSet(at index: Int) -> SetEntry? {
        guard let lastSessionSets = historyVM.previousSets(forExerciseId: exercise.exerciseId), !lastSessionSets.isEmpty else {
            return nil
        }
        return lastSessionSets.indices.contains(index) ? lastSessionSets[index] : lastSessionSets.last
    }
}

/// `.swipeActions` only works inside a `List` — this screen uses a plain
/// ScrollView/LazyVStack for its card-based layout, so swipe-to-delete is
/// implemented directly via a drag gesture that reveals a trailing delete button.
private struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let deleteWidth: CGFloat = 72

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(role: .destructive) {
                    Haptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                        .frame(width: deleteWidth)
                        .frame(maxHeight: .infinity)
                }
                .background(Color.red)
            }
            .padding(.horizontal, 8) // matches SetRow's own internal horizontal padding, so the two align exactly at rest

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black) // opaque so it fully occludes the delete button behind it at rest
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .updating($dragOffset) { value, state, _ in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            state = max(-deleteWidth, min(0, offset + value.translation.width)) - offset
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = value.translation.width < -40 ? -deleteWidth : 0
                            }
                        }
                )
        }
    }
}

private struct SetRow: View {
    let index: Int
    let set: SetEntry
    let previousSet: SetEntry?
    let onToggle: () -> Void
    let onToggleWarmup: () -> Void
    let onWeightChange: (Double) -> Void
    let onRepsChange: (Int) -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var justCompleted = false
    @ObservedObject private var settings = SettingsStore.shared
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps }

    var body: some View {
        HStack {
            Button(action: onToggleWarmup) {
                Text(set.isWarmup ? "W" : "\(index)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(set.isWarmup ? .orange : .white)
                    .frame(width: 30, alignment: .leading)
            }

            Group {
                if let previousSet, previousSet.weight > 0 || previousSet.reps > 0 {
                    Text("\(Formatters.weight(previousSet.weight, unit: settings.weightUnit))×\(previousSet.reps)")
                } else {
                    Text("—")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.4))
            .frame(width: 74, alignment: .leading)

            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .foregroundStyle(.white)
                .tint(Theme.accent)
                .frame(maxWidth: .infinity)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { _, newValue in
                    let entered = Double(newValue) ?? 0
                    onWeightChange(Formatters.toStorageWeight(entered, unit: settings.weightUnit))
                }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .tint(Theme.accent)
                .frame(maxWidth: .infinity)
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { _, newValue in
                    onRepsChange(Int(newValue) ?? 0)
                }

            Button(action: {
                if !set.isCompleted {
                    Haptics.rigid()
                    justCompleted.toggle()
                } else {
                    Haptics.selection()
                }
                onToggle()
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .white : .white.opacity(0.25))
                    .scaleEffect(set.isCompleted ? 1.15 : 1.0)
                    .symbolEffect(.bounce, value: justCompleted)
            }
            .frame(width: 36)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: set.isCompleted)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(set.isCompleted ? Color.green.opacity(0.55) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            resyncWeightText()
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
        .onChange(of: set.weight) { _, _ in if focusedField != .weight { resyncWeightText() } }
        .onChange(of: set.reps) { _, newValue in
            if focusedField != .reps { repsText = newValue > 0 ? "\(newValue)" : "" }
        }
        .onChange(of: settings.weightUnit) { _, _ in resyncWeightText() }
    }

    private func resyncWeightText() {
        weightText = set.weight > 0 ? Formatters.weight(set.weight, unit: settings.weightUnit) : ""
    }
}
