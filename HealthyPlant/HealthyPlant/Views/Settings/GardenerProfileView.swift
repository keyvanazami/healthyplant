import SwiftUI
import PhotosUI
import CoreLocation

struct GardenerProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = GardenerViewModel()
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showFollowing = false
    @State private var showSavedToast = false
    @State private var isDetectingLocation = false
    @State private var locationHelper = LocationHelper()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if !authService.isAccountLinked {
                    signInBanner
                } else {
                    ScrollView {
                        VStack(spacing: 28) {
                            avatarSection
                            rankBadge
                            statsRow
                            bioSection
                            climateZoneSection
                            experienceSection
                            privacySection
                            saveButton
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("My Gardener Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .task { await viewModel.loadMyProfile() }
            .sheet(isPresented: $showFollowing) {
                FollowingListView(viewModel: viewModel)
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Sections

    private var avatarSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let img = viewModel.pendingAvatarImage {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                    } else if let urlStr = viewModel.myProfile.avatarURL,
                              let url = URL(string: urlStr) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            avatarPlaceholder
                        }
                    } else {
                        avatarPlaceholder
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth))

                Circle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                    )
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
    }

    private var rankBadge: some View {
        let rank = viewModel.myProfile.rank
        return HStack(spacing: 6) {
            Image(systemName: rank.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(rank.color)
            Text(rank.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(rank.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(rank.color.opacity(0.12))
        .cornerRadius(20)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.15))
            Image(systemName: "person.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.accent)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Text("\(viewModel.myProfile.followerCount)")
                    .font(.title2.bold())
                    .foregroundColor(Theme.textPrimary)
                Text("Followers")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Divider().frame(height: 36).background(Theme.accent.opacity(0.3))

            Button {
                showFollowing = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(viewModel.myProfile.followingCount)")
                        .font(.title2.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .greenOutline(cornerRadius: 14)
    }

    private var bioSection: some View {
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
                        if val.count > 300 { viewModel.editBio = String(val.prefix(300)) }
                    }
            }
            .frame(minHeight: 90)

            Text("\(viewModel.editBio.count)/300")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
    }

    private var climateZoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("USDA Hardiness Zone", systemImage: "thermometer.sun")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)

            HStack(spacing: 8) {
                TextField("e.g. 9b", text: $viewModel.editClimateZone)
                    .foregroundColor(Theme.textPrimary)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .greenOutline(cornerRadius: 10)

                Button {
                    Task { await detectClimateZone() }
                } label: {
                    Group {
                        if isDetectingLocation {
                            ProgressView().tint(Theme.accent).scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(Theme.accent.opacity(0.12))
                    .cornerRadius(10)
                }
                .disabled(isDetectingLocation)
            }
            .padding(.horizontal, 20)

            Text("Tap to detect your zone from location")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)
        }
    }

    private func detectClimateZone() async {
        isDetectingLocation = true
        defer { isDetectingLocation = false }
        do {
            let location = try await locationHelper.getLocation()
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let postalCode = placemarks.first?.postalCode else { return }
            let url = URL(string: "https://phzmapi.org/\(postalCode).json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            struct ZoneResponse: Decodable { let zone: String }
            let response = try JSONDecoder().decode(ZoneResponse.self, from: data)
            viewModel.editClimateZone = response.zone
        } catch {}
    }

    private var experienceSection: some View {
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
    }

    private var privacySection: some View {
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
        .padding(.horizontal, 20)
    }

    private var saveButton: some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            if showSavedToast {
                Text("Profile saved!")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.accent)
            }
        Button {
            Task {
                await viewModel.saveProfile()
                if viewModel.errorMessage == nil {
                    showSavedToast = true
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showSavedToast = false
                }
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(.black)
                } else {
                    Text("Save Profile")
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
        .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var signInBanner: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent.opacity(0.6))

            Text("Sign in to set up your gardener profile")
                .font(.title3.bold())
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Your gardener profile lets the community discover you and follow your plants.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                Button {
                    Task { try? await authService.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                }

                NavigationLink {
                    EmailAuthView(isPresented: .constant(true))
                        .navigationBarHidden(true)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text("Continue with Email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(Theme.accent)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Following List Sheet

struct FollowingListView: View {
    @ObservedObject var viewModel: GardenerViewModel
    @State private var following: [GardenerProfile] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(Theme.accent)
                } else if following.isEmpty {
                    Text("Not following anyone yet")
                        .foregroundColor(Theme.textSecondary)
                } else {
                    List(following, id: \.userId) { profile in
                        GardenerRowView(profile: profile)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .task {
                do {
                    following = try await GardenerService().fetchMyFollowing()
                } catch {}
                isLoading = false
            }
        }
    }
}

// MARK: - Gardener Row

struct GardenerRowView: View {
    let profile: GardenerProfile

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlStr = profile.avatarURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { Circle().fill(Theme.accent.opacity(0.2)) }
                } else {
                    Circle().fill(Theme.accent.opacity(0.15))
                        .overlay(Image(systemName: "person.fill").foregroundColor(Theme.accent))
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName ?? "Gardener")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                if let exp = profile.experienceLevel {
                    Text(exp.label)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Location Helper

final class LocationHelper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func getLocation() async throws -> CLLocation {
        manager.requestWhenInUseAuthorization()
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            self.manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations[0])
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

#Preview {
    GardenerProfileView()
        .environmentObject(AuthService())
}
