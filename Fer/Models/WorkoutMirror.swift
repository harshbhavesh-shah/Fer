//
//  WorkoutMirror.swift
//  Fer
//
//  Lightweight snapshot of an in-progress workout sent between iPhone and
//  Watch over WatchConnectivity, plus the actions the Watch can send back.
//  Kept in the iOS target but also added to the Watch target's membership
//  (see SETUP-WATCH.md) since both sides need the same Codable shape.
//

import Foundation

struct WorkoutMirrorSnapshot: Codable {
    var routineName: String
    var exercises: [LoggedExercise]
    var elapsed: TimeInterval
    var isResting: Bool
    var restRemaining: Int
    var restTotal: Int
    var currentExerciseIndex: Int
}

enum WatchAction: Codable {
    case toggleSet(exerciseIndex: Int, setIndex: Int)
    case addSet(exerciseIndex: Int)
    case skipRest
    case addRestTime(seconds: Int)
    case finish
    case discard

    private enum Kind: String, Codable { case toggleSet, addSet, skipRest, addRestTime, finish, discard }
    private enum CodingKeys: String, CodingKey { case kind, exerciseIndex, setIndex, seconds }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .toggleSet:
            self = .toggleSet(exerciseIndex: try c.decode(Int.self, forKey: .exerciseIndex),
                               setIndex: try c.decode(Int.self, forKey: .setIndex))
        case .addSet:
            self = .addSet(exerciseIndex: try c.decode(Int.self, forKey: .exerciseIndex))
        case .skipRest:
            self = .skipRest
        case .addRestTime:
            self = .addRestTime(seconds: try c.decode(Int.self, forKey: .seconds))
        case .finish:
            self = .finish
        case .discard:
            self = .discard
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .toggleSet(let exerciseIndex, let setIndex):
            try c.encode(Kind.toggleSet, forKey: .kind)
            try c.encode(exerciseIndex, forKey: .exerciseIndex)
            try c.encode(setIndex, forKey: .setIndex)
        case .addSet(let exerciseIndex):
            try c.encode(Kind.addSet, forKey: .kind)
            try c.encode(exerciseIndex, forKey: .exerciseIndex)
        case .skipRest:
            try c.encode(Kind.skipRest, forKey: .kind)
        case .addRestTime(let seconds):
            try c.encode(Kind.addRestTime, forKey: .kind)
            try c.encode(seconds, forKey: .seconds)
        case .finish:
            try c.encode(Kind.finish, forKey: .kind)
        case .discard:
            try c.encode(Kind.discard, forKey: .kind)
        }
    }
}
