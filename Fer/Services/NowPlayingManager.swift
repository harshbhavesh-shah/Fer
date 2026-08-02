//
//  NowPlayingManager.swift
//  Fer
//
//  Unified "whatever is playing" facade. Delegates to whichever
//  NowPlayingSource is selected in Settings — Apple Music works out of the
//  box; Spotify activates automatically once its SDK has been added (see
//  SETUP-SPOTIFY.md) since SpotifyNowPlayingSource compiles to nothing
//  until then.
//

import Foundation
import Combine
import UIKit

protocol NowPlayingSource: AnyObject {
    var statePublisher: AnyPublisher<NowPlayingState, Never> { get }
    func play()
    func pause()
    func next()
    func previous()
    func seek(to progress: Double)
}

struct NowPlayingState: Equatable {
    var title: String = ""
    var artist: String = ""
    var artwork: UIImage? = nil
    var isPlaying: Bool = false
    var elapsed: TimeInterval = 0
    var duration: TimeInterval = 0
    var isAvailable: Bool = false

    static func == (lhs: NowPlayingState, rhs: NowPlayingState) -> Bool {
        lhs.title == rhs.title && lhs.artist == rhs.artist && lhs.isPlaying == rhs.isPlaying
            && lhs.elapsed == rhs.elapsed && lhs.duration == rhs.duration && lhs.isAvailable == rhs.isAvailable
    }
}

@MainActor
final class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published private(set) var state = NowPlayingState()

    private var source: NowPlayingSource?
    private var cancellable: AnyCancellable?
    private let appleMusic = AppleMusicNowPlayingSource()

    private init() {
        attach(appleMusic)
    }

    /// Call after changing `SettingsStore.nowPlayingSource` to switch the active source.
    func refreshSource() {
        switch SettingsStore.shared.nowPlayingSource {
        case .appleMusic:
            attach(appleMusic)
        case .spotify:
            if let spotify = Self.makeSpotifySource() {
                attach(spotify)
            } else {
                attach(appleMusic)
            }
        }
    }

    private func attach(_ source: NowPlayingSource) {
        self.source = source
        cancellable = source.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
    }

    func play() { source?.play() }
    func pause() { source?.pause() }
    func next() { source?.next() }
    func previous() { source?.previous() }
    func seek(to progress: Double) { source?.seek(to: progress) }

    /// Non-nil only when the Spotify SDK has actually been linked (see SpotifyNowPlayingSource.swift).
    private static func makeSpotifySource() -> NowPlayingSource? {
        #if canImport(SpotifyiOS)
        return SpotifyNowPlayingSource()
        #else
        return nil
        #endif
    }
}
