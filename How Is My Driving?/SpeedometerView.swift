//  SpeedoMeterView.swift
//  How Is My Driving?

import SwiftUI

struct SpeedometerView: View {
    @Binding var currentSpeed: Double
    @Binding var postedLimit: Double
    @Binding var unit: String
    private let maxSpeedDisplayMPH: Double = 120

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.1)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(currentSpeed / maxSpeedDisplayMPH, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(currentSpeed > postedLimit && postedLimit > 0 ? .red : .blue)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear(duration: 0.5), value: currentSpeed)

            if postedLimit > 0 && postedLimit <= maxSpeedDisplayMPH {
                 SpeedLimitMarkerView(limit: postedLimit, maxSpeed: maxSpeedDisplayMPH, gaugeRadius: 115 - 10)
            }

            VStack(spacing: 2) {
                Text("\(Int(currentSpeed))")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                Text(unit.uppercased())
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                if postedLimit > 0 {
                    Text("Limit: \(Int(postedLimit)) \(unit.uppercased())")
                        .font(.caption)
                        .foregroundColor(currentSpeed > postedLimit ? .red : .secondary)
                        .padding(.top, 5)
                } else {
                    Text("Limit: N/A")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .padding(.top, 5)
                }
            }
        }
    }
}

struct SpeedLimitMarkerView: View {
    let limit: Double
    let maxSpeed: Double
    let gaugeRadius: CGFloat

    var angle: Angle {
        let proportion = limit / maxSpeed
        return Angle(degrees: (proportion * 360) - 90)
    }

    var body: some View {
        Rectangle()
            .fill(Color.orange)
            .frame(width: 3, height: 15)
            .offset(y: -gaugeRadius)
            .rotationEffect(angle)
    }
}

struct TripControlButtonModifier: ViewModifier {
    var color: Color
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minWidth: 80)
            .background(isDisabled ? Color.gray.opacity(0.3) : color.opacity(0.2))
            .foregroundColor(isDisabled ? .gray : color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDisabled ? Color.gray.opacity(0.5) : color, lineWidth: 1)
            )
            .disabled(isDisabled)
    }
}
