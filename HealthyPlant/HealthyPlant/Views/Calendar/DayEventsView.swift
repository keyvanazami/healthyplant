import SwiftUI

struct DayEventsView: View {
    let date: Date
    let events: [CalendarEvent]
    @ObservedObject var viewModel: CalendarViewModel
    let profiles: [PlantProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateEvent = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.accent.opacity(0.4))

                        Text("No events for this day")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(events) { event in
                            EventRowView(event: event) {
                                Task {
                                    await viewModel.markComplete(eventId: event.id)
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(date.mediumFormatted)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateCalendarEventView(
                    date: date,
                    profiles: profiles,
                    viewModel: viewModel
                )
            }
        }
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let event: CalendarEvent
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Colored type indicator
            Circle()
                .fill(event.eventType.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.plantName)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.textPrimary)

                Text(event.description)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Completion checkbox
            Button(action: onToggle) {
                Image(systemName: event.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(event.completed ? Theme.accent : Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(event.completed ? 0.6 : 1.0)
    }
}

#Preview {
    DayEventsView(
        date: .now,
        events: CalendarEvent.mockList,
        viewModel: CalendarViewModel(),
        profiles: [.mock]
    )
}
