import SwiftUI

/// Displays a  week strip, AM/PM routine cards, and a link to reminder settings.
/// Uses the shared `RoutineViewModel` injected from `RootView` so assignments made from
/// the Products tab appear here instantly.
struct MyRoutineScreen: View {
    // Uses the same RoutineViewModel the app injects in RootView
    @EnvironmentObject private var vm: RoutineViewModel
    let theme: AppTheme

    // Local date state for the week strip
    @State private var selectedDate: Date = Date()
    private let cal = Calendar(identifier: .gregorian)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Header with month + week strip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(selectedDate, format: .dateTime.year().month(.wide))
                            .font(.largeTitle.bold())
                        Spacer()
                        HStack(spacing: 12) {
                            Button { moveDay(-7) } label: { Image(systemName: "chevron.left") }
                            Button { selectedDate = Date() } label: { Text("Today") }
                            Button { moveDay(+7) } label: { Image(systemName: "chevron.right") }
                        }
                        .buttonStyle(.plain)
                    }
                    WeekStripMR(
                        theme: theme,
                        days: week(for: selectedDate),
                        selected: selectedDate
                    ) { d in selectedDate = d }
                }
                .padding(.horizontal)

                // AM / PM cards
                VStack(spacing: 16) {
                    RoutineCardMR_NoTicks(
                        title: "Rise and Shine",
                        icon: "alarm",
                        time: amTimeString,
                        color: theme.primary,
                        steps: steps(for: "AM")
                    )
                    RoutineCardMR_NoTicks(
                        title: "Wind Down",
                        icon: "moon",
                        time: pmTimeString,
                        color: theme.primary,
                        steps: steps(for: "PM")
                    )
                }
                .padding(.horizontal)

                // Empty state if there are no routines/slots at all
                if vm.routines.flatMap({ $0.slots }).isEmpty {
                    ContentStateView(
                        icon: "calendar.badge.plus",
                        title: "No routine yet",
                        message: "Use the Products tab to add items to AM/PM steps."
                    )
                    .padding(.horizontal)
                }

                // Reminders subpage entry
                NavigationLink {
                    RemindersSettingsView()
                        .environmentObject(vm) // pass same VM
                } label: {
                    GroupBox {
                        HStack {
                            Label("Reminders", systemImage: "bell.badge")
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("AM: \(amTimeString)")
                                    .foregroundStyle(vm.notif.enableAM ? .primary : .secondary)
                                Text("PM: \(pmTimeString)")
                                    .foregroundStyle(vm.notif.enablePM ? .primary : .secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            vm.load()                // load routines/products + notif prefs
            selectedDate = Date()
        }
        .navigationTitle("Routine")
        .animation(.default, value: vm.routines) // animate card updates when assignments change
    }

    // MARK: - Helpers

    /// Build step list for a routine title ("AM" or "PM").
    private func steps(for title: String) -> [(slot: RoutineSlot, productName: String?)] {
        guard let routine = vm.routines.first(where: { $0.title.lowercased() == title.lowercased() }) else { return [] }
        return routine.slots.map { slot in
            let name = slot.productID.flatMap { vm.productsByID[$0]?.name }
            return (slot, name)
        }
    }

    private var amTimeString: String {
        Self.timeFormatter.string(from: dateFrom(hour: vm.notif.amHour, minute: vm.notif.amMinute))
    }
    private var pmTimeString: String {
        Self.timeFormatter.string(from: dateFrom(hour: vm.notif.pmHour, minute: vm.notif.pmMinute))
    }

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter(); df.timeStyle = .short; return df
    }()

    private func dateFrom(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
    private func moveDay(_ delta: Int) {
        selectedDate = cal.date(byAdding: .day, value: delta, to: selectedDate) ?? selectedDate
    }
    private func week(for base: Date) -> [Date] {
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)) ?? base
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

// Weekly strip (unchanged)
private struct WeekStripMR: View {
    let theme: AppTheme
    let days: [Date]
    let selected: Date
    var onSelect: (Date) -> Void

    private let cal = Calendar(identifier: .gregorian)

    var body: some View {
        HStack(spacing: 10) {
            ForEach(days, id: \.self) { day in
                let isToday = cal.isDateInToday(day)
                let isSelected = cal.isDate(day, inSameDayAs: selected)
                VStack(spacing: 6) {
                    Text(day, format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(cal.component(.day, from: day))")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .background((isSelected ? theme.primary : .clear).opacity(0.2))
                        .overlay(Circle().stroke(isToday ? theme.primary : .clear, lineWidth: 1))
                        .clipShape(Circle())
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelect(day) }
            }
        }
    }
}

// Routine card (display-only)
private struct RoutineCardMR_NoTicks: View {
    let title: String
    let icon: String
    let time: String
    let color: Color
    let steps: [(slot: RoutineSlot, productName: String?)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon).font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
            }
            Text(time).foregroundStyle(.secondary)

            if steps.isEmpty {
                Text("No steps configured yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            ForEach(steps, id: \.slot.id) { pair in
                HStack(spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(color.opacity(0.8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pair.slot.step).bold()
                        Text(pair.productName ?? "No product selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
