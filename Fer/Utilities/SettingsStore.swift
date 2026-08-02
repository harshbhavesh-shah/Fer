//
//  SettingsStore.swift
//  Fer
//
//  Device-local user preferences (not synced to Firestore — these affect
//  only how this device displays/enters data, not the underlying model).
//

import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var weightUnit: UserProfile.WeightUnit {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: Keys.weightUnit) }
    }

    @Published var defaultRestSeconds: Int {
        didSet { UserDefaults.standard.set(defaultRestSeconds, forKey: Keys.defaultRestSeconds) }
    }

    @Published var nowPlayingSource: NowPlayingSourceKind {
        didSet { UserDefaults.standard.set(nowPlayingSource.rawValue, forKey: Keys.nowPlayingSource) }
    }

    enum NowPlayingSourceKind: String, CaseIterable {
        case appleMusic, spotify

        var label: String {
            switch self {
            case .appleMusic: return "Apple Music"
            case .spotify: return "Spotify"
            }
        }
    }

    private enum Keys {
        static let weightUnit = "settings.weightUnit"
        static let defaultRestSeconds = "settings.defaultRestSeconds"
        static let nowPlayingSource = "settings.nowPlayingSource"
    }

    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Keys.weightUnit), let unit = UserProfile.WeightUnit(rawValue: raw) {
            weightUnit = unit
        } else {
            weightUnit = .lb
        }
        let storedRest = defaults.integer(forKey: Keys.defaultRestSeconds)
        defaultRestSeconds = storedRest > 0 ? storedRest : 90
        if let raw = defaults.string(forKey: Keys.nowPlayingSource), let source = NowPlayingSourceKind(rawValue: raw) {
            nowPlayingSource = source
        } else {
            nowPlayingSource = .appleMusic
        }
    }
}
