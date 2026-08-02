//
//  SpotifyNowPlayingSource.swift
//  Fer
//
//  Compiles to nothing until SpotifyiOS.xcframework is added to the Fer
//  target — see SETUP-SPOTIFY.md for the (manual, external-account-gated)
//  setup steps. Once the SDK is linked, this activates automatically with
//  no further code changes; NowPlayingManager picks it up via
//  `#if canImport(SpotifyiOS)`.
//
//  You must also set `spotifyClientId` / `spotifyRedirectURL` below to the
//  values from your Spotify Developer Dashboard app.
//

#if canImport(SpotifyiOS)
import Foundation
import Combine
import SpotifyiOS
import UIKit

final class SpotifyNowPlayingSource: NSObject, NowPlayingSource {
    private static let spotifyClientId = "YOUR_SPOTIFY_CLIENT_ID"
    private static let spotifyRedirectURL = URL(string: "fer-spotify-auth://spotify-callback")!

    private let subject = CurrentValueSubject<NowPlayingState, Never>(NowPlayingState())
    private lazy var configuration = SPTConfiguration(clientID: Self.spotifyClientId, redirectURL: Self.spotifyRedirectURL)
    private lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        return remote
    }()

    var statePublisher: AnyPublisher<NowPlayingState, Never> {
        subject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        connect()
    }

    private func connect() {
        guard let token = appRemote.connectionParameters.accessToken, !token.isEmpty else {
            // First-time auth: this bounces out to the Spotify app and back via
            // spotifyRedirectURL, which your app must handle in
            // application(_:open:options:) / onOpenURL by calling
            // appRemote.authorizationParameters(from: url) and reconnecting.
            appRemote.authorizeAndPlayURI("")
            return
        }
        appRemote.connect()
    }

    func play() { appRemote.playerAPI?.resume(nil) }
    func pause() { appRemote.playerAPI?.pause(nil) }
    func next() { appRemote.playerAPI?.skip(toNext: nil) }
    func previous() { appRemote.playerAPI?.skip(toPrevious: nil) }
    func seek(to progress: Double) {
        appRemote.playerAPI?.getPlayerState { [weak self] result, _ in
            guard let state = result as? SPTAppRemotePlayerState else { return }
            let position = Int(Double(state.track.duration) * progress)
            self?.appRemote.playerAPI?.seek(toPosition: position, callback: nil)
        }
    }

    private func refresh(from playerState: SPTAppRemotePlayerState) {
        var state = NowPlayingState(
            title: playerState.track.name,
            artist: playerState.track.artist.name,
            artwork: nil,
            isPlaying: !playerState.isPaused,
            elapsed: TimeInterval(playerState.playbackPosition) / 1000,
            duration: TimeInterval(playerState.track.duration) / 1000,
            isAvailable: true
        )
        subject.send(state)
        appRemote.imageAPI?.fetchImage(forItem: playerState.track, with: CGSize(width: 600, height: 600)) { [weak self] image, _ in
            state.artwork = image as? UIImage
            self?.subject.send(state)
        }
    }
}

extension SpotifyNowPlayingSource: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        subject.send(NowPlayingState(isAvailable: false))
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        subject.send(NowPlayingState(isAvailable: false))
    }
}

extension SpotifyNowPlayingSource: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        refresh(from: playerState)
    }
}
#endif
