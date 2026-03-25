import SwiftUI

struct CreateCalendarEventView: View {
    let date: Date
    let profiles: [PlantProfile]
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProfile: PlantProfile?
    @State private var selectedEventType: CalendarEvent.EventType = .needsWater
    @State private var description: String = ""

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                Form {
                    // Plant picker
                    Section {
                        Picker("Plant", selection: $selectedProfile) {
                            ForEach(profiles) { profile in
                                Text(profile.name)
                                    .tag(Optional(profile))
                            }
                        }
                        .foregroundColor(Theme.textPrimary)
                    } header: {
                        Text("Plant")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // Event type picker
                    Section {
                        Picker("Event Type", selection: $selectedEventType) {
                            ForEach(CalendarEvent.EventType.allCases, id: \.self) { type in
                                Text(type.label)
                                    .tag(type)
                            }
                        }
                        .foregroundColor(Theme.textPrimary)
                    } header: {
                        Text("Event Type")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // Description
                    Section {
                        TextField("Water thoroughly", text: $description)
                            .foregroundColor(Theme.textPrimary)
                    } header: {
                        Text("Description (optional)")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let profile = selectedProfile else { return }
                        Task {
                            await viewModel.createEvent(
                                profileId: profile.id,
                                plantName: profile.name,
                                date: dateString,
                                eventType: selectedEventType.rawValue,
                                description: description
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(Theme.accent)
                    .fontWeight(.semibold)
                    .disabled(selectedProfile == nil)
                }
            }
            .onAppear {
                if selectedProfile == nil {
                    selectedProfile = profiles.first
                }
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    CreateCalendarEventView(
        date: .now,
        profiles: [.mock],
        viewModel: CalendarViewModel()
    )
}
