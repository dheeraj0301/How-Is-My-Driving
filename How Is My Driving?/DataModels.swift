//
//  DataModels.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation // For location permissions
import CoreMotion // For motion permissions
import PhotosUI // For Photo Picker

// Represents a single driving event
struct DrivingEvent: Identifiable, Codable, Hashable {
    let id = UUID()
    var type: EventType
    var points: Int
    var timestamp: Date
    var description: String {
        return "\(type.rawValue): \(points > 0 ? "+" : "")\(points) pts"
    }
    // Optional: Add magnitude for events like speeding or harsh maneuvers
    var magnitude: Double? = nil
    var duration: TimeInterval? = nil // For events like prolonged speeding

    enum EventType: String, Codable, CaseIterable {
        // Negative Behaviors
        case harshBraking = "Harsh Braking"
        case rapidAcceleration = "Rapid Acceleration" // Could be "Hard Acceleration"
        case aggressiveLeftTurn = "Aggressive Left Turn"
        case aggressiveRightTurn = "Aggressive Right Turn"
        case aggressiveSpeeding = "Aggressive Speeding" // Exceeding limit significantly
        case prolongedSpeeding = "Prolonged Speeding" // Speeding for a duration
        case suddenLaneChange = "Sudden Lane Change" // More complex, placeholder for now
        case phoneUsage = "Phone Usage" // Currently Simulated

        // Positive Behaviors
        case smoothDriving = "Smooth Driving Interval"
        case adherenceToSpeedLimit = "Speed Limit Adherence"
        case gentleManeuver = "Gentle Maneuver" // Could be more specific like "Smooth Turn"
        case maintainingSafeDistance = "Safe Following Distance" // Advanced, placeholder
        case efficientAcceleration = "Efficient Acceleration" // Positive counterpart to rapid accel

        // Neutral/Informational
        case tripStart = "Trip Started"
        case tripEnd = "Trip Ended"
        case tripPause = "Trip Paused"
        case tripResume = "Trip Resumed"
    }
}

// User profile data
struct UserProfile: Codable {
    var name: String = ""
    var age: String = "" // Storing as String for flexibility
    var profileImageData: Data?
}
