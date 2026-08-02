//
//  UserProfile.swift
//  Fer
//
//  Plain `id` (not @DocumentID) — shared with the Watch target, which can't
//  import FirebaseFirestore (no watchOS support).
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String?
    var displayName: String = ""
    var email: String = ""
    var weightUnit: WeightUnit = .lb
    var createdAt: Date = Date()

    enum WeightUnit: String, Codable, CaseIterable {
        case lb, kg
        var label: String { rawValue }
    }
}
