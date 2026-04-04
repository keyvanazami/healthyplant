import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var sensorViewModel = SensorViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showUserGuide = false
    @State private var showAddSensor = false
    @State private var isSigningIn = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List {
                    // Account
                    Section("Account") {
                        if authService.isGoogleLinked {
                            HStack(spacing: 12) {
                                if let photoURL = authService.photoURL {
                                    AsyncImage(url: photoURL) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(Theme.accent)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(Theme.accent)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(authService.displayName ?? "Google User")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(authService.email ?? "")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .listRowBackground(Color.white.opacity(0.05))

                            Button(role: .destructive) {
                                showSignOutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        } else {
                            Button {
                                Task {
                                    isSigningIn = true
                                    try? await authService.signInWithGoogle()
                                    isSigningIn = false
                                }
                            } label: {
                                HStack {
                                    if isSigningIn {
                                        ProgressView().tint(Theme.accent)
                                    } else {
                                        Image(systemName: "g.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Theme.accent)
                                    }
                                    Text("Sign in with Google")
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .disabled(isSigningIn)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }

                    // App Info
                    Section("App Info") {
                        HStack {
                            Text("Version")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text(viewModel.appVersion)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.handleVersionTap()
                        }

                        HStack {
                            Text("Healthy Plant")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("🌵")
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    // Developer (hidden until unlocked via 5x version tap)
                    if viewModel.devModeUnlocked {
                        Section("Developer") {
                            HStack {
                                Circle()
                                    .fill(viewModel.isDevelopment ? Color.orange : Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Environment")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(viewModel.isDevelopment ? "Development" : "Production")
                                    .foregroundColor(Theme.textSecondary)
                                    .font(.footnote)
                            }
                            .listRowBackground(Color.white.opacity(0.05))

                            Toggle(isOn: $viewModel.isDevelopment) {
                                HStack {
                                    Image(systemName: "hammer.fill")
                                        .foregroundColor(.orange)
                                    Text("Use Dev Server")
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .tint(.orange)
                            .listRowBackground(Color.white.opacity(0.05))
                            .onChange(of: viewModel.isDevelopment) { _, _ in
                                viewModel.toggleEnvironment()
                            }
                        }
                    }

                    // Sensors
                    Section("Sensors") {
                        ForEach(sensorViewModel.sensors) { sensor in
                            HStack {
                                Circle()
                                    .fill(sensor.status == "online" ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                Text(sensor.name)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(sensor.sensorId)
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }

                        Button {
                            showAddSensor = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.accent)
                                Text("Add Sensor")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    // Help
                    Section("Help") {
                        Button {
                            showUserGuide = true
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(Theme.accent)
                                Text("User Guide")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }

                    // Notifications
                    Section("Notifications") {
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Theme.accent)
                                Text("Push Notifications")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .tint(Theme.accent)
                        .listRowBackground(Color.white.opacity(0.05))
                        .onChange(of: viewModel.notificationsEnabled) { _, _ in
                            viewModel.toggleNotifications()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .task {
                await sensorViewModel.loadSensors()
            }
            .sheet(isPresented: $showAddSensor, onDismiss: {
                Task { await sensorViewModel.loadSensors() }
            }) {
                AddSensorView(viewModel: sensorViewModel, profiles: [])
            }
            .fullScreenCover(isPresented: $showUserGuide) {
                NavigationStack {
                    OnboardingView(isComplete: $showUserGuide, isRevisit: true)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { showUserGuide = false }
                                    .foregroundColor(Theme.accent)
                            }
                        }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your data will remain on this device but won't sync to other devices until you sign in again.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
