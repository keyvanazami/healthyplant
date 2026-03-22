import SwiftUI
import PhotosUI

struct CreateProfileView: View {
    @ObservedObject var viewModel: ProfilesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var plantType = ""
    @State private var ageDays = 0
    @State private var heightFeet = 0
    @State private var heightInches = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false

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

                        TextField("Plant Type (e.g. Tomato)", text: $plantType)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // Age
                    Section("Age") {
                        Stepper("Age: \(ageDays) days", value: $ageDays, in: 0...9999)
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
                    Button("Save") {
                        save()
                    }
                    .foregroundColor(canSave ? Theme.accent : Theme.textSecondary)
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPickerView: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }

    // MARK: - Logic

    private var canSave: Bool {
        !name.isBlank && !plantType.isBlank
    }

    private func save() {
        guard canSave else { return }
        isSaving = true

        Task {
            await viewModel.createProfile(
                name: name.trimmed,
                plantType: plantType.trimmed,
                ageDays: ageDays,
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
