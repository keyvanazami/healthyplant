import SwiftUI

struct SensorReadingCard: View {
    let reading: SensorLastReading?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sensor.fill")
                    .foregroundColor(Theme.accent)
                Text("Live Sensor Data")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                Spacer()
                if let ts = reading?.timestamp {
                    Text(relativeTime(ts))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            if let r = reading {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    gaugeItem(
                        icon: "drop.fill",
                        color: .blue,
                        label: "Soil Moisture",
                        value: r.soilMoisture,
                        unit: "%",
                        maxValue: 100
                    )
                    gaugeItem(
                        icon: "sun.max.fill",
                        color: .yellow,
                        label: "Light",
                        value: r.lightLux,
                        unit: " lux",
                        maxValue: 50000
                    )
                    gaugeItem(
                        icon: "thermometer.medium",
                        color: .orange,
                        label: "Temperature",
                        value: r.temperature,
                        unit: "°C",
                        maxValue: 50
                    )
                    gaugeItem(
                        icon: "humidity.fill",
                        color: .cyan,
                        label: "Humidity",
                        value: r.humidity,
                        unit: "%",
                        maxValue: 100
                    )
                }
            } else {
                Text("Waiting for first reading...")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .greenOutline(cornerRadius: 16)
    }

    private func gaugeItem(icon: String, color: Color, label: String,
                           value: Double?, unit: String, maxValue: Double) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(min((value ?? 0) / maxValue, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            if let v = value {
                Text(formatValue(v) + unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            } else {
                Text("--")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func formatValue(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }

    private func relativeTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let mins = Int(-date.timeIntervalSinceNow / 60)
        if mins < 1 { return "just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hours = mins / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
