//
//  EventRow.swift
//  How Is My Driving?
//
import SwiftUI

struct EventRow: View {
    let event: DrivingEvent

    var iconName: String {
        switch event.type {
        case .harshBraking: return "arrow.down.to.line.compact"
        case .rapidAcceleration: return "arrow.up.to.line.compact"
        case .aggressiveLeftTurn: return "arrow.turn.up.left"
        case .aggressiveRightTurn: return "arrow.turn.up.right"
        case .aggressiveSpeeding: return "gauge.badge.plus"
        case .prolongedSpeeding: return "timer"
        case .suddenLaneChange: return "arrow.left.arrow.right.circle"
        case .phoneUsage: return "iphone.slash"
        case .smoothDriving: return "leaf.fill"
        case .adherenceToSpeedLimit: return "checkmark.shield.fill"
        case .gentleManeuver: return "figure.walk"
        case .maintainingSafeDistance: return "car.2.fill"
        case .efficientAcceleration: return "bolt.badge.a.fill"
        case .tripStart: return "play.fill"
        case .tripEnd: return "stop.fill"
        case .tripPause: return "pause.fill"
        case .tripResume: return "play.fill"
        }
    }

    var iconColor: Color {
        if event.points < 0 { return .red }
        if event.points > 0 { return .green }
        return .gray
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 25, alignment: .center)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.rawValue)
                    .font(.headline)
                
                HStack {
                    Text(event.timestamp, style: .time)
                    Text("|")
                    Text(event.timestamp, style: .date)
                }
                .font(.caption)
                .foregroundColor(.gray)

                if let magnitude = event.magnitude {
                    let formattedMagnitude = String(format: "%.1f", magnitude)
                    Text("Severity: \(formattedMagnitude)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                if let duration = event.duration {
                     let formattedDuration = String(format: "%.1fs", duration)
                     Text("Duration: \(formattedDuration)")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            Spacer()
            if event.type != .tripStart && event.type != .tripEnd && event.type != .tripPause && event.type != .tripResume {
                Text("\(event.points > 0 ? "+" : "")\(event.points) pts")
                    .font(.headline)
                    .foregroundColor(iconColor)
                    .padding(.leading, 5)
            }
        }
        .padding(.vertical, 6)
    }
}
