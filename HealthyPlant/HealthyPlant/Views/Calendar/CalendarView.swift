import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate: IdentifiableDate?

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    calendarGrid
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Calendar")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.generateSchedule() }
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView()
                                .tint(Theme.accent)
                        } else {
                            Label("Generate Schedule", systemImage: "sparkles")
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .disabled(viewModel.isGenerating)
                }
            }
            .refreshable {
                await viewModel.generateSchedule()
            }
            .sheet(item: $selectedDate) { item in
                DayEventsView(
                    date: item.date,
                    events: viewModel.eventsForDay(item.date),
                    viewModel: viewModel,
                    profiles: viewModel.profiles
                )
                .presentationDetents([.medium, .large])
            }
            .task {
                await viewModel.loadEvents(for: viewModel.currentMonth)
                await viewModel.loadProfiles()
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    viewModel.currentMonth = viewModel.currentMonth.addingMonths(-1)
                }
                Task { await viewModel.loadEvents(for: viewModel.currentMonth) }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.accent)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.currentMonth.monthYearFormatted)
                .font(.title3.bold())
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button {
                withAnimation {
                    viewModel.currentMonth = viewModel.currentMonth.addingMonths(1)
                }
                Task { await viewModel.loadEvents(for: viewModel.currentMonth) }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.accent)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let firstWeekday = viewModel.currentMonth.startOfMonth.firstWeekdayOfMonth
        let daysInMonth = viewModel.currentMonth.daysInMonth
        let totalCells = firstWeekday + daysInMonth
        let totalRows = (totalCells + 6) / 7
        let gridCells = totalRows * 7

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<gridCells, id: \.self) { index in
                let dayNumber = index - firstWeekday + 1
                if dayNumber >= 1 && dayNumber <= daysInMonth {
                    let date = dateForDay(dayNumber)
                    DayCellView(
                        day: dayNumber,
                        date: date,
                        events: viewModel.eventsForDay(date),
                        isToday: date.isSameDay(as: .now)
                    )
                    .onTapGesture {
                        selectedDate = IdentifiableDate(date: date)
                    }
                } else {
                    Color.clear.frame(height: 50)
                }
            }
        }
        .id(viewModel.currentMonth.monthYearFormatted)
    }

    private func dateForDay(_ day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month], from: viewModel.currentMonth)
        components.day = day
        return Calendar.current.date(from: components) ?? viewModel.currentMonth
    }
}

// MARK: - Day Cell

struct DayCellView: View {
    let day: Int
    let date: Date
    let events: [CalendarEvent]
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .black : Theme.textPrimary)
                .frame(width: 28, height: 28)
                .background(isToday ? Theme.accent : Color.clear)
                .clipShape(Circle())

            // Event dots
            HStack(spacing: 3) {
                let uniqueTypes = Array(Set(events.map(\.eventType)))
                ForEach(uniqueTypes.prefix(3), id: \.self) { type in
                    Circle()
                        .fill(type.color)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 8)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

// MARK: - Identifiable Date Wrapper

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

#Preview {
    CalendarView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
