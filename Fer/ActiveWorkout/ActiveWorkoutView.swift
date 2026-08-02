//
//  ActiveWorkoutView.swift
//  Fer
//

import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    @Binding var activeWorkout: WorkoutSessionViewModel?
    @ObservedObject var historyVM: HistoryViewModel
    let onMinimize: () -> Void

    @State private var showingPicker = false
    @State private var showingDiscardConfirm = false
    @State private var showingSummary = false

    @GestureState private var openDragOffset: CGFloat = 0
    @GestureState private var closeDragOffset: CGFloat = 0
    @State private var nowPlayingOpen = false

    /// Width of the edge zone that recognizes the "open" swipe — kept
    /// edge-anchored (like iOS's own edge-swipe-back) so it never competes
    /// with the workout ScrollView's vertical pan or the per-row
    /// swipe-to-delete gesture. Also shown as a visible handle (below) so
    /// the feature is discoverable, not just a hidden gesture.
    private let edgeZoneWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                workoutContent

                if !nowPlayingOpen {
                    NowPlayingHandle(onTap: openNowPlaying)
                        .frame(width: edgeZoneWidth)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .updating($openDragOffset) { value, state, _ in
                                    guard value.translation.width < 0, abs(value.translation.width) > abs(value.translation.height) else { return }
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    if value.translation.width < -40 { openNowPlaying() }
                                }
                        )
                        .frame(maxHeight: .infinity)
                }

                if nowPlayingOpen {
                    NowPlayingView { closeNowPlaying() }
                        .offset(x: max(0, closeDragOffset))
                        .gesture(
                            DragGesture(minimumDistance: 15)
                                .updating($closeDragOffset) { value, state, _ in
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    if value.translation.width > 60 { closeNowPlaying() }
                                }
                        )
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: nowPlayingOpen)
            .animation(.interactiveSpring(), value: openDragOffset)
        }
    }

    private func openNowPlaying() {
        Haptics.medium()
        NowPlayingManager.shared.refreshSource()
        nowPlayingOpen = true
    }

    private func closeNowPlaying() {
        Haptics.light()
        nowPlayingOpen = false
    }

    private var workoutContent: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseLogCard(
                                exercise: exercise,
                                historyVM: historyVM,
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
                                onRemoveExercise: {
                                    withAnimation { viewModel.removeExercise(at: index) }
                                }
                            )
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                        }

                        Button {
                            Haptics.light()
                            showingPicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primaryAction(color: .blue))

                        if viewModel.exercises.isEmpty {
                            EmptyStateView(icon: "dumbbell", title: "Add your first exercise", message: "Tap below to pick something from the library.")
                        }
                    }
                    .padding()
                    .padding(.bottom, viewModel.isResting ? 100 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.exercises)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .top) {
                    WorkoutStatsHeader(viewModel: viewModel)
                }

                if viewModel.isResting {
                    RestTimerBar(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(viewModel.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onMinimize()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard") { showingDiscardConfirm = true }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") {
                        Haptics.success()
                        showingSummary = true
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.totalSetsCompleted == 0)
                }
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
    }
}

/// Sticky stats row pinned above the scrolling exercise list — Hevy-style
/// at-a-glance volume/duration/sets, always visible regardless of scroll
/// position (unlike the old single duration readout in the nav bar).
private struct WorkoutStatsHeader: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        HStack(spacing: 0) {
            stat(value: Formatters.weight(viewModel.totalVolume, unit: settings.weightUnit), label: settings.weightUnit.label.uppercased())
            Divider().frame(height: 28)
            stat(value: Formatters.duration(viewModel.elapsed), label: "DURATION")
            Divider().frame(height: 28)
            stat(value: "\(viewModel.totalSetsCompleted)", label: "SETS")
        }
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .statNumberStyle()
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Visible tab docked to the trailing edge, hinting that Now Playing can be
/// pulled open — tapping it opens immediately (no gesture finesse needed),
/// and it also sits inside the drag zone for the swipe-to-open gesture.
private struct NowPlayingHandle: View {
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: "music.note")
                    .symbolEffect(.variableColor.iterative, isActive: nowPlaying.state.isPlaying)
                Image(systemName: "chevron.left")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .frame(width: 28, height: 72)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, style: .continuous)
                    .fill(Theme.gradient(for: Theme.accent))
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: -2)
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseLogCard: View {
    let exercise: LoggedExercise
    @ObservedObject var historyVM: HistoryViewModel
    let onAddSet: () -> Void
    let onToggleSet: (Int) -> Void
    let onRemoveSet: (Int) -> Void
    let onUpdateWeight: (Int, Double) -> Void
    let onUpdateReps: (Int, Int) -> Void
    let onRemoveExercise: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.exerciseName).font(.headline)
                Spacer()
                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive, action: onRemoveExercise)
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("SET").frame(width: 30, alignment: .leading)
                Text("PREV").frame(width: 64, alignment: .leading)
                Text("WEIGHT (\(SettingsStore.shared.weightUnit.label.uppercased()))").frame(maxWidth: .infinity, alignment: .leading)
                Text("REPS").frame(maxWidth: .infinity, alignment: .leading)
                Text("").frame(width: 36)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                SwipeToDeleteRow(onDelete: { onRemoveSet(index) }) {
                    SetRow(
                        index: index + 1,
                        set: set,
                        previousSet: previousSet(at: index),
                        onToggle: { onToggleSet(index) },
                        onWeightChange: { onUpdateWeight(index, $0) },
                        onRepsChange: { onUpdateReps(index, $0) }
                    )
                }
            }

            Button(action: onAddSet) {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bouncy)
            .padding(.top, 4)
        }
        .cardStyle()
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
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            content
                .background(Color(.systemBackground).opacity(0.001)) // keeps the whole row hit-testable
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SetRow: View {
    let index: Int
    let set: SetEntry
    let previousSet: SetEntry?
    let onToggle: () -> Void
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
            Text("\(index)")
                .font(.subheadline.weight(.semibold))
                .frame(width: 30, alignment: .leading)
                .foregroundStyle(set.isWarmup ? .orange : .primary)

            Group {
                if let previousSet, previousSet.weight > 0 || previousSet.reps > 0 {
                    Text("\(Formatters.weight(previousSet.weight, unit: settings.weightUnit))×\(previousSet.reps)")
                } else {
                    Text("—")
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(width: 64, alignment: .leading)

            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { _, newValue in
                    let entered = Double(newValue) ?? 0
                    onWeightChange(Formatters.toStorageWeight(entered, unit: settings.weightUnit))
                }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { _, newValue in
                    onRepsChange(Int(newValue) ?? 0)
                }

            Button(action: {
                if !set.isCompleted { justCompleted.toggle() }
                onToggle()
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                    .scaleEffect(set.isCompleted ? 1.15 : 1.0)
                    .symbolEffect(.bounce, value: justCompleted)
            }
            .frame(width: 36)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: set.isCompleted)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(set.isCompleted ? Color.green.opacity(0.12) : Color.clear)
        )
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
