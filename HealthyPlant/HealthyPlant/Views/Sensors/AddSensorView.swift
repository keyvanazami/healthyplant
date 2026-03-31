import SwiftUI

struct AddSensorView: View {
    @ObservedObject var viewModel: SensorViewModel
    let profiles: [PlantProfile]
    @Environment(\.dismiss) private var dismiss

    @State private var sensorId = ""
    @State private var sensorName = ""
    @State private var selectedProfileId: String?
    @State private var registeredSensor: Sensor?
    @State private var isRegistering = false
    @State private var step = 0  // 0 = enter ID, 1 = pick profile, 2 = done

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    if step == 0 {
                        enterIdStep
                    } else if step == 1 {
                        pickProfileStep
                    } else {
                        doneStep
                    }
                }
                .padding(24)
            }
            .navigationTitle("Add Sensor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    // MARK: - Step 0: Enter sensor ID

    private var enterIdStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "sensor.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.accent)

            Text("Enter Sensor ID")
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.textPrimary)

            Text("Find the sensor ID on the setup page when you connect to the sensor's WiFi, or on the label.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            TextField("e.g. HP-A1B2C3", text: $sensorId)
                .textInputAutocapitalization(.characters)
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)

            TextField("Sensor name", text: $sensorName)
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)

            Button {
                Task { await registerAndContinue() }
            } label: {
                Group {
                    if isRegistering {
                        ProgressView().tint(.black)
                    } else {
                        Text("Register Sensor")
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent)
                .cornerRadius(12)
            }
            .disabled(sensorId.isEmpty || sensorName.isEmpty || isRegistering)
            .opacity(sensorId.isEmpty || sensorName.isEmpty ? 0.5 : 1)

            Spacer()
        }
    }

    // MARK: - Step 1: Pick profile

    private var pickProfileStep: some View {
        VStack(spacing: 20) {
            Text("Link to a Plant")
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.textPrimary)

            Text("Which plant is this sensor monitoring?")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            if let token = registeredSensor?.deviceToken {
                VStack(spacing: 4) {
                    Text("Device Token")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(token)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.accent)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    Text("Enter this token in the sensor's setup page")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(profiles) { profile in
                        Button {
                            selectedProfileId = profile.id
                        } label: {
                            HStack {
                                Text(profile.name)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(profile.plantType)
                                    .foregroundColor(Theme.textSecondary)
                                    .font(.caption)
                                if selectedProfileId == profile.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .padding()
                            .background(selectedProfileId == profile.id
                                        ? Theme.accent.opacity(0.1) : Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Skip") {
                    step = 2
                }
                .foregroundColor(Theme.textSecondary)

                Button {
                    Task { await pairAndFinish() }
                } label: {
                    Text("Pair & Finish")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .cornerRadius(12)
                }
                .disabled(selectedProfileId == nil)
                .opacity(selectedProfileId == nil ? 0.5 : 1)
            }
        }
    }

    // MARK: - Step 2: Done

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent)

            Text("Sensor Added!")
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.textPrimary)

            Text("Your sensor will start sending data once it connects to WiFi with the device token.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions

    private func registerAndContinue() async {
        isRegistering = true
        let sensor = await viewModel.registerSensor(
            sensorId: sensorId.trimmingCharacters(in: .whitespacesAndNewlines),
            name: sensorName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        isRegistering = false

        if let sensor {
            registeredSensor = sensor
            step = 1
        }
    }

    private func pairAndFinish() async {
        guard let profileId = selectedProfileId,
              let sensor = registeredSensor else { return }
        await viewModel.pairSensor(sensorId: sensor.sensorId, profileId: profileId)
        step = 2
    }
}
