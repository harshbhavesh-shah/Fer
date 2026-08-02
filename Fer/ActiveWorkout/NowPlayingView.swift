//
//  NowPlayingView.swift
//  Fer
//
//  Full-screen "Now Playing" card revealed by swiping left on the Active
//  Workout screen. Liquid Glass background (iOS 26) so the workout screen
//  stays subtly visible underneath.
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    let onClose: () -> Void

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 28) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.top, 12)

                Capsule()
                    .fill(.white.opacity(0.4))
                    .frame(width: 40, height: 5)

                Spacer()

                if nowPlaying.state.isAvailable {
                    artwork
                    trackInfo
                    progressBar
                    controls
                } else {
                    emptyState
                }

                Spacer()

                Text("Swipe right to go back to your workout")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular.tint(Theme.accent.opacity(0.25)), in: Rectangle())
        }
        .ignoresSafeArea()
        .onTapGesture(count: 2) { onClose() }
    }

    private var artwork: some View {
        Group {
            if let image = nowPlaying.state.artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay(Image(systemName: "music.note").font(.system(size: 60)).foregroundStyle(.white.opacity(0.5)))
            }
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(nowPlaying.state.title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(nowPlaying.state.artist)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let fraction = nowPlaying.state.duration > 0 ? nowPlaying.state.elapsed / nowPlaying.state.duration : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule().fill(.white).frame(width: geo.size.width * max(0, min(1, fraction)))
                }
                .gesture(
                    DragGesture(minimumDistance: 0).onEnded { value in
                        let progress = max(0, min(1, value.location.x / geo.size.width))
                        nowPlaying.seek(to: progress)
                        Haptics.light()
                    }
                )
            }
            .frame(height: 4)

            HStack {
                Text(Formatters.duration(nowPlaying.state.elapsed))
                Spacer()
                Text(Formatters.duration(nowPlaying.state.duration))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var controls: some View {
        HStack(spacing: 44) {
            Button {
                Haptics.light()
                nowPlaying.previous()
            } label: {
                Image(systemName: "backward.fill").font(.title2)
            }

            Button {
                Haptics.medium()
                if nowPlaying.state.isPlaying {
                    nowPlaying.pause()
                } else {
                    nowPlaying.play()
                }
            } label: {
                Image(systemName: nowPlaying.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
            }

            Button {
                Haptics.light()
                nowPlaying.next()
            } label: {
                Image(systemName: "forward.fill").font(.title2)
            }
        }
        .foregroundStyle(.white)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.5))
            Text("Nothing playing").font(.headline).foregroundStyle(.white)
            Text("Start something in \(SettingsStore.shared.nowPlayingSource.label) and it'll show up here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}
