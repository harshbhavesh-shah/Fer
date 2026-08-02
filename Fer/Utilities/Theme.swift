//
//  Theme.swift
//  Fer
//
//  Shared design tokens: colors, gradients, spacing, and reusable
//  view modifiers used across the app for a consistent, polished look.
//

import SwiftUI

enum Theme {
    // Hardcoded rather than Color("AccentColor") — the default Xcode
    // AccentColor.colorset ships with no color assigned, which made every
    // gradient button in the app (including Sign In) render nearly invisible.
    // Less saturated/purple than before — a cleaner, more neutral blue in
    // line with a data-forward (Hevy-like) look rather than a playful one.
    static let accent = Color(red: 0.17, green: 0.42, blue: 0.93)

    static let background = LinearGradient(
        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Tighter than before (was 20) — reads as denser/more data-forward,
    // less "playful rounded bubble."
    static let cardCorner: CGFloat = 14
    static let spacing: CGFloat = 16

    static func gradient(for color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    /// Consistent bold monospaced-digit style for at-a-glance stat numbers
    /// (Dashboard pills, workout stats header, etc.) — reads more like a
    /// data readout than the app's default rounded/friendly type.
    func statNumberStyle() -> some View {
        font(.system(.title3, design: .rounded, weight: .bold))
            .monospacedDigit()
    }
}

/// A soft, elevated card container used throughout the app.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }

    /// A bouncy press-down scale effect for buttons/cards.
    func pressEffect(_ isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
    }
}

/// A button style with spring scale + haptic on press.
struct BouncyButtonStyle: ButtonStyle {
    var haptic: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && haptic { Haptics.light() }
            }
    }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Theme.gradient(for: color))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.medium() }
            }
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static func primaryAction(color: Color = Theme.accent) -> PrimaryActionButtonStyle {
        PrimaryActionButtonStyle(color: color)
    }
}
