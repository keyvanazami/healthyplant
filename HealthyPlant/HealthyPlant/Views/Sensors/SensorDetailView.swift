import SwiftUI
import Charts

struct SensorDetailView: View {
    let sensor: Sensor
    @ObservedObject var sensorViewModel: SensorViewModel
    @ObservedObject var profilesViewModel: ProfilesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0  // 0 = History, 1 = Link Plant
    @State private var selectedMetric = "soilMoisture"
    @State private var isLinking = false
    @State private var selectedProfileId: String?

    private let metrics: [(key: String, label: String, unit: String, color: Color)] = [
        ("soilMoisture", "Soil Moisture", "%", .blue),
        ("temperature",  "Temperature",   "°C", .orange),
        ("humidity",     "Humidity",       "%", .cyan),
        ("lightLux",     "Light",          " lux", .yellow),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("History").tag(0)
                        Text("Link Plant").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedTab == 0 {
                        historyTab
                    } else {
                        linkTab
                    }
                }
            }
            .navigationTitle(sensor.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .task {
                await sensorViewModel.loadHistory(for: sensor.sensorId, hoursBack: 24)
                await profilesViewModel.loadProfiles()
                selectedProfileId = sensor.profileId
            }
        }
    }

    // MARK: - History Tab

    private var historyTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Metric picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(metrics, id: \.key) { m in
                            Button {
                                selectedMetric = m.key
                            } label: {
                                Text(m.label)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedMetric == m.key ? Theme.accent : Color.white.opacity(0.08))
                                    .foregroundColor(selectedMetric == m.key ? .black : Theme.textSecondary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                let readings = sensorViewModel.readingHistory
                let metric = metrics.first { $0.key == selectedMetric }!

                if readings.isEmpty {
                    Text("No readings yet")
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 60)
                } else {
                    // Chart
                    Chart {
                        ForEach(readings) { reading in
                            if let val = value(of: reading, metric: selectedMetric),
                               let date = parseDate(reading.timestamp) {
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value(metric.label, val)
                                )
                                .foregroundStyle(metric.color)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Time", date),
                                    y: .value(metric.label, val)
                                )
                                .foregroundStyle(metric.color.opacity(0.1))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel(format: .dateTime.hour().minute())
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .frame(height: 220)
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Latest value
                    if let latest = readings.first,
                       let val = value(of: latest, metric: selectedMetric) {
                        HStack {
                            Text("Latest")
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("\(formatVal(val))\(metric.unit)")
                                .font(.body.weight(.semibold))
                                .foregroundColor(metric.color)
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Reading list
                    VStack(spacing: 1) {
                        ForEach(readings.prefix(20)) { reading in
                            if let val = value(of: reading, metric: selectedMetric),
                               let date = parseDate(reading.timestamp) {
                                HStack {
                                    Text(date, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Text("\(formatVal(val))\(metric.unit)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.03))
                            }
                        }
                    }
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Link Tab

    private var linkTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let currentId = sensor.profileId,
                   let profile = profilesViewModel.profiles.first(where: { $0.id == currentId }) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Theme.accent)
                        Text("Currently linked to \(profile.name)")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.accent.opacity(0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    Text("Not linked to any plant")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .padding()
                }

                ForEach(profilesViewModel.profiles) { profile in
                    Button {
                        selectedProfileId = profile.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .foregroundColor(Theme.textPrimary)
                                Text(profile.plantType)
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            if selectedProfileId == profile.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .padding()
                        .background(selectedProfileId == profile.id
                            ? Theme.accent.opacity(0.1) : Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Button {
                    Task { await linkToSelected() }
                } label: {
                    Group {
                        if isLinking {
                            ProgressView().tint(.black)
                        } else {
                            Text(selectedProfileId == nil ? "Unlink Sensor" : "Save Link")
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLinking)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Actions

    private func linkToSelected() async {
        isLinking = true
        if let profileId = selectedProfileId {
            await sensorViewModel.pairSensor(sensorId: sensor.sensorId, profileId: profileId)
        } else {
            await sensorViewModel.unpairSensor(sensorId: sensor.sensorId)
        }
        isLinking = false
        dismiss()
    }

    // MARK: - Helpers

    private func value(of reading: SensorReading, metric: String) -> Double? {
        switch metric {
        case "soilMoisture":  return reading.soilMoisture
        case "temperature":   return reading.temperature
        case "humidity":      return reading.humidity
        case "lightLux":      return reading.lightLux
        default:              return nil
        }
    }

    private func parseDate(_ iso: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
    }

    private func formatVal(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
