import SwiftUI
import PhotosUI

struct GardenerProfileSetupView: View {
    @Binding var isComplete: Bool
    @StateObject private var viewModel = GardenerViewModel()
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Set Up Your Gardener Profile")
                                .font(.title2.bold())
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("Optional — you can skip and set this up later in Settings.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)

                        // Avatar picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let img = viewModel.pendingAvatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Theme.accent.opacity(0.15))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Theme.accent)
                                }
                                Circle()
                                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    viewModel.setAvatarImage(img)
                                }
                            }
                        }

                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Label("About You", systemImage: "text.quote")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.textSecondary)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .greenOutline(cornerRadius: 12)

                                if viewModel.editBio.isEmpty {
                                    Text("Tell the community about your garden...")
                                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                                        .padding(12)
                                }

                                TextEditor(text: $viewModel.editBio)
                                    .foregroundColor(Theme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 80)
                                    .onChange(of: viewModel.editBio) { _, val in
                                        if val.count > 300 {
                                            viewModel.editBio = String(val.prefix(300))
                                        }
                                    }
                            }
                            .frame(minHeight: 90)

                            Text("\(viewModel.editBio.count)/300")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)

                        // Experience
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Experience Level", systemImage: "star.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                ForEach(GardeningExperience.allCases) { level in
                                    ExperienceCard(
                                        level: level,
                                        isSelected: viewModel.editExperience == level
                                    )
                                    .onTapGesture {
                                        viewModel.editExperience = viewModel.editExperience == level ? nil : level
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Privacy toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $viewModel.editIsPublic) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share profile publicly")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Others can discover you in the community")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .tint(Theme.accent)
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .greenOutline(cornerRadius: 12)
                        }
                        .padding(.horizontal, 20)

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.saveProfile()
                                    if viewModel.errorMessage == nil {
                                        isComplete = true
                                    }
                                }
                            } label: {
                                HStack {
                                    if viewModel.isSaving {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text("Get Started")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.accent)
                                .foregroundColor(.black)
                                .cornerRadius(14)
                            }
                            .disabled(viewModel.isSaving)

                            Button("Skip for Now") {
                                isComplete = true
                            }
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Experience Card

struct ExperienceCard: View {
    let level: GardeningExperience
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: level.icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .black : Theme.accent)

            Text(level.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : Theme.textPrimary)

            Text(level.description)
                .font(.system(size: 10))
                .foregroundColor(isSelected ? .black.opacity(0.7) : Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? Theme.accent : Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Theme.accent : Theme.accent.opacity(0.3),
                              lineWidth: isSelected ? 2 : Theme.outlineWidth)
        )
    }
}

#Preview {
    GardenerProfileSetupView(isComplete: .constant(false))
        .environmentObject(AuthService())
}
