//
//  AppleMusicNowPlayingSource.swift
//  Fer
//
//  Controls/reads the system music player (Apple Music app + local
//  library). Requires NSAppleMusicUsageDescription in Info.plist.
//

import Foundation
import MediaPlayer
import Combine

final class AppleMusicNowPlayingSource: NowPlayingSource {
    private let player = MPMusicPlayerController.systemMusicPlayer
    private let subject: CurrentValueSubject<NowPlayingState, Never>

    var statePublisher: AnyPublisher<NowPlayingState, Never> {
        subject.eraseToAnyPublisher()
    }

    init() {
        subject = CurrentValueSubject(NowPlayingState())
        player.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(
            self, selector: #selector(refresh),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(refresh),
            name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player
        )
        refresh()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player.endGeneratingPlaybackNotifications()
    }

    @objc private func refresh() {
        guard let item = player.nowPlayingItem else {
            subject.send(NowPlayingState(isAvailable: false))
            return
        }
        let artwork = item.artwork?.image(at: CGSize(width: 600, height: 600))
        subject.send(NowPlayingState(
            title: item.title ?? "Unknown Title",
            artist: item.artist ?? "Unknown Artist",
            artwork: artwork,
            isPlaying: player.playbackState == .playing,
            elapsed: player.currentPlaybackTime,
            duration: item.playbackDuration,
            isAvailable: true
        ))
    }

    func play() { player.play(); refresh() }
    func pause() { player.pause(); refresh() }
    func next() { player.skipToNextItem(); refresh() }
    func previous() { player.skipToPreviousItem(); refresh() }
    func seek(to progress: Double) {
        guard let item = player.nowPlayingItem else { return }
        player.currentPlaybackTime = item.playbackDuration * progress
        refresh()
    }
}
