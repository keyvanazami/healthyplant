import SwiftUI
import PhotosUI

struct CreateProfileView: View {
    @ObservedObject var viewModel: ProfilesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var plantType = ""
    @State private var ageYears = 0
    @State private var ageMonths = 0
    @State private var ageDaysOnly = 0
    @State private var heightFeet = 0
    @State private var heightInches = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var isIdentifying = false
    @State private var identifyTrigger = 0  // incremented to trigger identification

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                Form {
                    // Photo section
                    Section {
                        HStack {
                            Spacer()
                            photoPickerView
                            Spacer()
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    // Plant details
                    Section("Plant Details") {
                        TextField("Plant Name", text: $name)
                            .foregroundColor(Theme.textPrimary)

                        HStack {
                            TextField("Plant Type (e.g. Tomato)", text: $plantType)
                                .foregroundColor(Theme.textPrimary)
                            if isIdentifying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Theme.accent)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // Age
                    Section("Age") {
                        Stepper("Years: \(ageYears)", value: $ageYears, in: 0...100)
                            .foregroundColor(Theme.textPrimary)

                        Stepper("Months: \(ageMonths)", value: $ageMonths, in: 0...11)
                            .foregroundColor(Theme.textPrimary)

                        Stepper("Days: \(ageDaysOnly)", value: $ageDaysOnly, in: 0...30)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // Height
                    Section("Height") {
                        Stepper("Feet: \(heightFeet)", value: $heightFeet, in: 0...30)
                            .foregroundColor(Theme.textPrimary)

                        Stepper("Inches: \(heightInches)", value: $heightInches, in: 0...11)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .tint(Theme.accent)
            }
            .navigationTitle("New Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Theme.accent)
                    } else {
                        Button("Save") {
                            save()
                        }
                        .foregroundColor(canSave ? Theme.accent : Theme.textSecondary)
                        .disabled(!canSave)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        identifyTrigger += 1
                    }
                }
            }
            .task(id: identifyTrigger) {
                guard identifyTrigger > 0, let data = selectedImageData else { return }
                await identifyPlant(from: data)
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPickerView: some View {
        Button {
            showImageSourcePicker = true
        } label: {
            Group {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(Theme.accent.opacity(0.15))
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                            Text("Add Photo")
                                .font(.caption)
                        }
                        .foregroundColor(Theme.accent)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth))
        }
        .confirmationDialog("Add Photo", isPresented: $showImageSourcePicker) {
            Button("Take Photo") {
                showCamera = true
            }
            Button("Choose from Library") {
                showPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if selectedImageData != nil {
                identifyTrigger += 1
            }
        }) {
            CameraView(imageData: $selectedImageData)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
    }

    // MARK: - Logic

    private var canSave: Bool {
        !name.isBlank
    }

    private var totalAgeDays: Int {
        (ageYears * 365) + (ageMonths * 30) + ageDaysOnly
    }

    private func identifyPlant(from imageData: Data) async {
        isIdentifying = true
        do {
            let result = try await ImageUploadService().identifyPlant(imageData)
            if !result.plantType.isEmpty {
                print("[CreateProfile] Identified plant: \(result.plantType)")
                plantType = result.plantType
            }
        } catch {
            print("[CreateProfile] Plant identification failed: \(error)")
        }
        isIdentifying = false
    }

    private func save() {
        guard canSave else { return }
        isSaving = true

        Task {
            await viewModel.createProfile(
                name: name.trimmed,
                plantType: plantType.trimmed,
                ageDays: totalAgeDays,
                heightFeet: heightFeet,
                heightInches: heightInches,
                imageData: selectedImageData
            )
            dismiss()
        }
    }
}

#Preview {
    CreateProfileView(viewModel: ProfilesViewModel())
}
