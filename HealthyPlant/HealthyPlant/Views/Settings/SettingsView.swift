import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

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

                        HStack {
                            Text("Healthy Plant")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("🌵")
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
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
