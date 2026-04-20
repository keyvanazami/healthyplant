import SwiftUI

struct HomeView: View {
    var isVisible: Bool = true
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings = false
    @State private var showGardenerProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with animated cactus + title
                        headerSection

                        // Stats strip
                        statsStrip

                        // Today's tasks
                        todayTasksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                                .frame(width: 36, height: 36)

                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGardenerProfile = true
                    } label: {
                        ZStack {
                            if let photoURL = authService.photoURL {
                                AsyncImage(url: photoURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Theme.accent.opacity(0.15))
                                }
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth))
                            } else {
                                Circle()
                                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showGardenerProfile) {
                GardenerProfileView()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .onChange(of: isVisible) { _, visible in
                if visible {
                    Task { await viewModel.loadDashboard() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            PlantAnimationView()
                .scaleEffect(0.45)
                .frame(width: 80, height: 120)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text("Healthy Plant")
                    .font(.title.bold())
                    .foregroundColor(Theme.textPrimary)

                Text(todayDateString)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 12) {
            statCapsule(
                icon: "leaf.fill",
                value: "\(viewModel.plants.count)",
                label: "Plants"
            )

            statCapsule(
                icon: "checklist",
                value: "\(viewModel.todayEvents.count)",
                label: "Tasks Today"
            )

            statCapsule(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.completedTodayCount)",
                label: "Done"
            )
        }
    }

    private func statCapsule(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.accent)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }

    // MARK: - Today's Tasks

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if viewModel.isLoading && viewModel.todayEvents.isEmpty && viewModel.plants.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Theme.accent)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if viewModel.todayEvents.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accent)

                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .greenOutline(cornerRadius: 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.todayEvents) { event in
                        taskRow(event: event)
                    }
                }
            }
        }
    }

    private func taskRow(event: CalendarEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.eventType.icon)
                .font(.system(size: 20))
                .foregroundColor(event.eventType.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.plantName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text(event.eventType.label)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.completeTask(eventId: event.id)
                }
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
