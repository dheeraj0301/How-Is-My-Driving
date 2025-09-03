//
//  DataModels.swift
//  How Is My Driving?

import SwiftUI

struct DrivingEvent: Identifiable, Codable, Hashable {
    var id = UUID()
    var type: EventType
    var points: Int
    var timestamp: Date
    var description: String {
        return "\(type.rawValue): \(points > 0 ? "+" : "")\(points) pts"
    }
    
    var magnitude: Double? = nil
    var duration: TimeInterval? = nil
    
    enum EventType: String, Codable, CaseIterable {
        // Negative Behaviors
        case harshBraking = "Harsh Braking"
        case rapidAcceleration = "Rapid Acceleration"
        case aggressiveLeftTurn = "Aggressive Left Turn"
        case aggressiveRightTurn = "Aggressive Right Turn"
        case aggressiveSpeeding = "Aggressive Speeding"
        case prolongedSpeeding = "Prolonged Speeding"
        case suddenLaneChange = "Sudden Lane Change"
        case phoneUsage = "Phone Usage"
        
        // Positive Behaviors
        case smoothDriving = "Smooth Driving Interval"
        case adherenceToSpeedLimit = "Speed Limit Adherence"
        case gentleManeuver = "Gentle Maneuver"
        case maintainingSafeDistance = "Safe Following Distance"
        case efficientAcceleration = "Efficient Acceleration"
        
        // Neutral/Informational
        case tripStart = "Trip Started"
        case tripEnd = "Trip Ended"
        case tripPause = "Trip Paused"
        case tripResume = "Trip Resumed"
    }
}

struct UserProfile: Codable {
    var name: String = ""
    var age: String = ""
    var profileImageData: Data?
}
