import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showUserGuide = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List {
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
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
