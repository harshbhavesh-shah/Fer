//
//  WatchHaptics.swift
//  Fer Watch App
//
//  watchOS haptics via WKInterfaceDevice — the iPhone target's Haptics.swift
//  uses UIImpactFeedbackGenerator (UIKit), which doesn't exist on watchOS,
//  so this is a separate, small equivalent just for the Watch app.
//

import WatchKit

enum WatchHaptics {
    static func success() {
        WKInterfaceDevice.current().play(.success)
    }

    static func failure() {
        WKInterfaceDevice.current().play(.failure)
    }

    static func click() {
        WKInterfaceDevice.current().play(.click)
    }

    static func start() {
        WKInterfaceDevice.current().play(.start)
    }

    static func stop() {
        WKInterfaceDevice.current().play(.stop)
    }

    static func notification() {
        WKInterfaceDevice.current().play(.notification)
    }
}
