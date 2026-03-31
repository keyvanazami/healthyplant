import SwiftUI
import PhotosUI

struct ProfileDetailView: View {
    let profile: PlantProfile
    @ObservedObject var viewModel: ProfilesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var isUploadingPhoto = false
    @StateObject private var communityViewModel = CommunityViewModel()
    @State private var showDisplayNamePrompt = false
    @State private var pendingDisplayName = ""

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

                // Delete button
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete Profile")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(10)
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(profile.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Share to community
                    Button {
                        if communityViewModel.isProfileShared(profile.id) {
                            Task { await communityViewModel.unshareProfile(profileId: profile.id) }
                        } else if communityViewModel.hasSetDisplayName {
                            Task { await communityViewModel.shareProfile(profileId: profile.id) }
                        } else {
                            pendingDisplayName = ""
                            showDisplayNamePrompt = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: communityViewModel.isProfileShared(profile.id)
                                  ? "globe.badge.chevron.backward"
                                  : "globe")
                                .font(.system(size: 18))
                            if communityViewModel.isProfileShared(profile.id) {
                                Text("Shared")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .foregroundColor(Theme.accent)
                    }

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
        .task {
            await communityViewModel.loadMyShared()
        }
        .sheet(isPresented: $showDisplayNamePrompt) {
            displayNameSheet
        }
        .alert("Delete Profile", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProfile(id: profile.id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(profile.name)\"? This action cannot be undone.")
        }
    }

    // MARK: - Photo

    private var profilePhoto: some View {
        Button {
            showImageSourcePicker = true
        } label: {
            ZStack {
                Group {
                    if let data = newImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFill()
                    } else if let urlString = profile.photoURL, let url = URL(string: urlString) {
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

                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                        Text(profile.photoURL != nil || newImageData != nil ? "Edit" : "Add Photo")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.85))
                    .cornerRadius(10)
                    .offset(y: -8)
                }
                .frame(width: 150, height: 150)

                if isUploadingPhoto {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 150, height: 150)
                    ProgressView()
                        .tint(Theme.accent)
                }
            }
            .overlay(Circle().strokeBorder(Theme.accent, lineWidth: 2))
        }
        .disabled(isUploadingPhoto)
        .confirmationDialog("Change Photo", isPresented: $showImageSourcePicker) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $newImageData)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    newImageData = data
                }
            }
        }
        .onChange(of: newImageData) { _, data in
            guard let data else { return }
            Task { await uploadPhoto(data) }
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.15))
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.accent)
        }
    }

    private func uploadPhoto(_ data: Data) async {
        isUploadingPhoto = true
        do {
            let imageService = ImageUploadService()
            let url = try await imageService.uploadImage(data)
            await viewModel.updateProfilePhoto(id: profile.id, photoURL: url)
            print("[ProfileDetail] Photo uploaded: \(url)")
        } catch {
            print("[ProfileDetail] Photo upload failed: \(error)")
        }
        isUploadingPhoto = false
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
            detailRow(label: "Age", value: profile.formattedAge)
            detailRow(label: "Height", value: profile.formattedHeight)
            detailRow(label: "Planted", value: profile.plantedDate)
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

            detailRow(label: "Sun Needs", value: profile.sunNeeds ?? "Analyzing...")

            if let minSun = profile.sunHoursMin, let maxSun = profile.sunHoursMax {
                detailRow(label: "Sun", value: "\(minSun)-\(maxSun) hours/day")
            } else if let minSun = profile.sunHoursMin {
                detailRow(label: "Sun", value: "\(minSun)+ hours/day")
            }

            detailRow(label: "Water Needs", value: profile.waterNeeds ?? "Analyzing...")

            if let days = profile.wateringFrequencyDays {
                detailRow(label: "Watering", value: "Every \(days) day\(days == 1 ? "" : "s")")
            }

            if let harvest = profile.harvestTime {
                detailRow(label: "Harvest Time", value: harvest)
            }

            if let lastUpdated = profile.aiLastUpdated {
                Text("AI last updated: \(lastUpdated)")
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


    private var displayNameSheet: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Set your display name")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text("This is how other plant lovers will see you in the community.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    TextField("Display name", text: $pendingDisplayName)
                        .foregroundColor(Theme.textPrimary)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)

                    Button {
                        let trimmed = pendingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = trimmed.isEmpty ? "Plant Lover" : trimmed
                        communityViewModel.saveDisplayName(finalName)
                        showDisplayNamePrompt = false
                        Task { await communityViewModel.shareProfile(profileId: profile.id) }
                    } label: {
                        Text("Save & Share")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .cornerRadius(12)
                    }
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showDisplayNamePrompt = false }
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
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
