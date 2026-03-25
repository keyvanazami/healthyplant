import SwiftUI

struct ProfileDetailView: View {
    let profile: PlantProfile
    @ObservedObject var viewModel: ProfilesViewModel
    @State private var isEditing = false

    // Editable fields
    @State private var name: String
    @State private var plantType: String
    @State private var ageDays: Int
    @State private var heightFeet: Int
    @State private var heightInches: Int

    init(profile: PlantProfile, viewModel: ProfilesViewModel) {
        self.profile = profile
        self.viewModel = viewModel
        _name = State(initialValue: profile.name)
        _plantType = State(initialValue: profile.plantType)
        _ageDays = State(initialValue: profile.ageDays)
        _heightFeet = State(initialValue: profile.heightFeet)
        _heightInches = State(initialValue: profile.heightInches)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Photo
                profilePhoto

                // Basic info
                infoSection

                Divider().background(Theme.accent.opacity(0.3))

                // AI-managed section
                aiSection

                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(profile.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .foregroundColor(Theme.accent)
            }
        }
    }

    // MARK: - Photo

    private var profilePhoto: some View {
        Group {
            if let urlString = profile.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    photoPlaceholder
                }
            } else {
                photoPlaceholder
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Theme.accent, lineWidth: 2))
    }

    private var photoPlaceholder: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.15))
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.accent)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            if isEditing {
                editableFields
            } else {
                readOnlyFields
            }
        }
    }

    private var readOnlyFields: some View {
        VStack(spacing: 12) {
            detailRow(label: "Name", value: profile.name)
            detailRow(label: "Type", value: profile.plantType)
            detailRow(label: "Age", value: "\(profile.ageDays) days")
            detailRow(label: "Height", value: profile.formattedHeight)
            detailRow(label: "Planted", value: profile.plantedDate.mediumFormatted)
        }
    }

    private var editableFields: some View {
        VStack(spacing: 12) {
            editField(label: "Name", text: $name)
            editField(label: "Type", text: $plantType)

            HStack {
                Text("Age (days)")
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Stepper("\(ageDays)", value: $ageDays, in: 0...9999)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 160)
            }

            HStack {
                Text("Height")
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Stepper("\(heightFeet)ft", value: $heightFeet, in: 0...30)
                    .frame(width: 120)
                Stepper("\(heightInches)in", value: $heightInches, in: 0...11)
                    .frame(width: 120)
            }
            .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - AI Section

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.accent)
                Text("AI-Managed Care")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
            }

            detailRow(label: "Sun Needs", value: profile.sunNeeds)

            if let minSun = profile.sunHoursMin, let maxSun = profile.sunHoursMax {
                detailRow(label: "Sun", value: "\(minSun)-\(maxSun) hours/day")
            } else if let minSun = profile.sunHoursMin {
                detailRow(label: "Sun", value: "\(minSun)+ hours/day")
            }

            detailRow(label: "Water Needs", value: profile.waterNeeds)

            if let days = profile.wateringFrequencyDays {
                detailRow(label: "Watering", value: "Every \(days) day\(days == 1 ? "" : "s")")
            }

            if let harvest = profile.harvestTime {
                detailRow(label: "Harvest Time", value: harvest)
            }

            if let lastUpdated = profile.aiLastUpdated {
                Text("AI last updated: \(lastUpdated.mediumFormatted)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .greenOutline(cornerRadius: 16)
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            TextField(label, text: text)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
        }
    }

    private func saveChanges() {
        Task {
            await viewModel.updateProfile(
                id: profile.id,
                name: name,
                plantType: plantType,
                ageDays: ageDays,
                heightFeet: heightFeet,
                heightInches: heightInches
            )
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView(
            profile: .mock,
            viewModel: ProfilesViewModel()
        )
    }
}
