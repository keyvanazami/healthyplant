import SwiftUI
import PhotosUI

struct PlantScanView: View {
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var lookupResult: PlantLookupResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddProfile = false
    @StateObject private var profilesViewModel = ProfilesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let result = lookupResult, let data = imageData {
                    resultView(result: result, imageData: data)
                } else if isLoading {
                    loadingView
                } else {
                    captureView
                }
            }
            .navigationTitle("Plant Scanner")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Capture View

    private var captureView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.accent)
            }

            Text("Scan a Plant")
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.textPrimary)

            Text("Take a photo or choose from your library to identify any plant and learn about its history, origin, and care.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(14)
                }

                Button {
                    showPhotoPicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cornerRadius(14)
                    .greenOutline(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 120)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(imageData: $imageData)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        .onChange(of: imageData) { _, data in
            guard let data else { return }
            Task { await lookupPlant(data) }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black.opacity(0.3))
                    )
            }

            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.accent)

            Text("Identifying plant...")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Searching for history, origin, and care info")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Result View

    private func resultView(result: PlantLookupResult, imageData: Data) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plant photo
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(16)
                }

                // Name + confidence
                VStack(spacing: 6) {
                    Text(result.plantType.isEmpty ? "Unknown Plant" : result.plantType)
                        .font(.title.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 8) {
                        confidenceBadge(result.confidence)
                        if !result.difficulty.isEmpty {
                            difficultyBadge(result.difficulty)
                        }
                    }

                    if !result.description.isEmpty {
                        Text(result.description)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }

                // Origin
                if !result.origin.isEmpty {
                    infoCard(icon: "globe.americas.fill", title: "Origin", content: result.origin)
                }

                // History
                if !result.history.isEmpty {
                    infoCard(icon: "book.fill", title: "History", content: result.history)
                }

                // Fun Facts
                if !result.funFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Fun Facts")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }

                        ForEach(Array(result.funFacts.enumerated()), id: \.offset) { _, fact in
                            HStack(alignment: .top, spacing: 8) {
                                Text("*")
                                    .foregroundColor(Theme.accent)
                                    .font(.headline)
                                Text(fact)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .greenOutline(cornerRadius: 16)
                }

                // Care summary
                if !result.careSummary.isEmpty {
                    infoCard(icon: "heart.fill", title: "Care Guide", content: result.careSummary)
                }

                // Quick care stats
                if !result.sunNeeds.isEmpty || !result.waterNeeds.isEmpty {
                    HStack(spacing: 12) {
                        if !result.sunNeeds.isEmpty {
                            quickStat(icon: "sun.max.fill", color: .yellow, label: "Sun", value: result.sunNeeds)
                        }
                        if !result.waterNeeds.isEmpty {
                            quickStat(icon: "drop.fill", color: .blue, label: "Water", value: result.waterNeeds)
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    if !result.plantType.isEmpty {
                        Button {
                            showAddProfile = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to My Plants")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .cornerRadius(14)
                        }
                    }

                    Button {
                        reset()
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan Another")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(14)
                        .greenOutline(cornerRadius: 14)
                    }
                }
                .padding(.top, 8)

                Spacer(minLength: 120)
            }
            .padding()
        }
        .sheet(isPresented: $showAddProfile, onDismiss: {
            Task { await profilesViewModel.loadProfiles() }
        }) {
            CreateProfileView(
                viewModel: profilesViewModel,
                prefillName: result.plantType,
                prefillType: result.plantType,
                prefillImageData: imageData
            )
        }
    }

    // MARK: - Components

    private func infoCard(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            Text(content)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .greenOutline(cornerRadius: 16)
    }

    private func quickStat(icon: String, color: Color, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.caption)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }

    private func confidenceBadge(_ level: String) -> some View {
        let color: Color = level == "high" ? .green : level == "medium" ? .orange : .red
        return Text(level.capitalized)
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }

    private func difficultyBadge(_ level: String) -> some View {
        let color: Color = level == "Easy" ? .green : level == "Moderate" ? .orange : .red
        return Text(level)
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }

    // MARK: - Actions

    private func lookupPlant(_ data: Data) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await ImageUploadService().lookupPlant(data)
            self.lookupResult = result
        } catch {
            errorMessage = "Failed to identify plant. Try again."
            self.imageData = nil
            print("[PlantScan] Lookup failed: \(error)")
        }
        isLoading = false
    }

    private func reset() {
        imageData = nil
        lookupResult = nil
        errorMessage = nil
        selectedPhotoItem = nil
    }
}

#Preview {
    PlantScanView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
