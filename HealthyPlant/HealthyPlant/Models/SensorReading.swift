import Foundation

struct Sensor: Codable, Identifiable {
    let id: String
    let sensorId: String
    var name: String
    var profileId: String?
    var firmwareVersion: String?
    var lastSeen: String?
    var batteryPercent: Int?
    var status: String
    var thresholds: SensorAlertThresholds?
    let createdAt: String

    /// The device token — only present in the registration response
    var deviceToken: String?
}

struct SensorAlertThresholds: Codable {
    var soilMoistureMin: Double?
    var soilMoistureMax: Double?
    var temperatureMin: Double?
    var temperatureMax: Double?
}

struct SensorReading: Codable, Identifiable {
    let id: String
    let timestamp: String
    let soilMoisture: Double?
    let lightLux: Double?
    let temperature: Double?
    let humidity: Double?
    let soilTemperature: Double?
    let pressure: Double?
}

struct SensorLastReading: Codable, Equatable, Hashable {
    let soilMoisture: Double?
    let lightLux: Double?
    let temperature: Double?
    let humidity: Double?
    let timestamp: String?
}
