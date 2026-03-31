import Foundation

@MainActor
final class SensorViewModel: ObservableObject {
    @Published var sensors: [Sensor] = []
    @Published var latestReadings: [String: SensorReading] = [:]
    @Published var readingHistory: [SensorReading] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SensorService()

    func loadSensors() async {
        isLoading = true
        do {
            sensors = try await service.fetchSensors()
            // Load latest reading for each sensor
            for sensor in sensors {
                if let reading = try? await service.fetchLatestReading(sensorId: sensor.sensorId) {
                    latestReadings[sensor.sensorId] = reading
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[SensorVM] Failed to load sensors: \(error)")
        }
        isLoading = false
    }

    func loadLatestReading(for sensorId: String) async {
        do {
            let reading = try await service.fetchLatestReading(sensorId: sensorId)
            latestReadings[sensorId] = reading
        } catch {
            print("[SensorVM] Failed to load reading for \(sensorId): \(error)")
        }
    }

    func loadHistory(for sensorId: String, hoursBack: Int = 24) async {
        do {
            readingHistory = try await service.fetchReadings(sensorId: sensorId, hoursBack: hoursBack)
        } catch {
            print("[SensorVM] Failed to load history for \(sensorId): \(error)")
        }
    }

    func registerSensor(sensorId: String, name: String) async -> Sensor? {
        do {
            let sensor = try await service.registerSensor(sensorId: sensorId, name: name)
            sensors.append(sensor)
            return sensor
        } catch {
            errorMessage = error.localizedDescription
            print("[SensorVM] Failed to register: \(error)")
            return nil
        }
    }

    func pairSensor(sensorId: String, profileId: String) async {
        do {
            let updated = try await service.pairSensor(sensorId: sensorId, profileId: profileId)
            if let idx = sensors.firstIndex(where: { $0.sensorId == sensorId }) {
                sensors[idx] = updated
            }
        } catch {
            print("[SensorVM] Failed to pair: \(error)")
        }
    }

    func unpairSensor(sensorId: String) async {
        do {
            let updated = try await service.unpairSensor(sensorId: sensorId)
            if let idx = sensors.firstIndex(where: { $0.sensorId == sensorId }) {
                sensors[idx] = updated
            }
        } catch {
            print("[SensorVM] Failed to unpair: \(error)")
        }
    }

    func deleteSensor(sensorId: String) async {
        do {
            try await service.deleteSensor(sensorId: sensorId)
            sensors.removeAll { $0.sensorId == sensorId }
            latestReadings.removeValue(forKey: sensorId)
        } catch {
            print("[SensorVM] Failed to delete: \(error)")
        }
    }
}
