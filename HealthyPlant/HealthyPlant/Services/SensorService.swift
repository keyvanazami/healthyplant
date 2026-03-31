import Foundation

struct SensorService {
    private let api = APIClient.shared

    func fetchSensors() async throws -> [Sensor] {
        try await api.get(path: "/api/v1/sensors")
    }

    func fetchSensor(id: String) async throws -> Sensor {
        try await api.get(path: "/api/v1/sensors/\(id)")
    }

    func registerSensor(sensorId: String, name: String) async throws -> Sensor {
        let body = RegisterBody(sensorId: sensorId, name: name)
        return try await api.post(path: "/api/v1/sensors/register", body: body)
    }

    func pairSensor(sensorId: String, profileId: String) async throws -> Sensor {
        let body = PairBody(profileId: profileId)
        return try await api.put(path: "/api/v1/sensors/\(sensorId)/pair", body: body)
    }

    func unpairSensor(sensorId: String) async throws -> Sensor {
        let body: [String: String] = [:]
        return try await api.put(path: "/api/v1/sensors/\(sensorId)/unpair", body: body)
    }

    func setThresholds(sensorId: String, thresholds: SensorAlertThresholds) async throws -> Sensor {
        try await api.put(path: "/api/v1/sensors/\(sensorId)/thresholds", body: thresholds)
    }

    func deleteSensor(sensorId: String) async throws {
        try await api.delete(path: "/api/v1/sensors/\(sensorId)")
    }

    func fetchLatestReading(sensorId: String) async throws -> SensorReading? {
        try await api.get(path: "/api/v1/sensors/\(sensorId)/latest")
    }

    func fetchReadings(sensorId: String, hoursBack: Int = 24) async throws -> [SensorReading] {
        try await api.get(path: "/api/v1/sensors/\(sensorId)/readings?hoursBack=\(hoursBack)")
    }
}

private struct RegisterBody: Encodable {
    let sensorId: String
    let name: String
}

private struct PairBody: Encodable {
    let profileId: String
}
