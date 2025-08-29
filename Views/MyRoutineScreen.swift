import SwiftUI

struct MyRoutineScreen: View {
    @EnvironmentObject private var vm: TimelineViewModel
    @EnvironmentObject private var app: AppModel
    let theme: AppTheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Header with month + week strip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(vm.selectedDate, format: .dateTime.year().month(.wide))
                            .font(.largeTitle.bold())
                        Spacer()
                        HStack(spacing: 12) {
                            Button { moveDay(-7) } label: { Image(systemName: "chevron.left") }
                            Button { moveDay(+7) } label: { Image(systemName: "chevron.right") }
                        }
                        .buttonStyle(.plain)
                    }
                    WeekStripMR(
                        theme: theme,
                        days: vm.week(for: vm.selectedDate),
                        selected: vm.selectedDate
                    ) { d in vm.selectedDate = d }
                }
                .padding(.horizontal)

                // AM / PM cards
                VStack(spacing: 16) {
                    RoutineCardMR(
                        title: "Rise and Shine",
                        icon: "alarm",
                        time: amTimeString,
                        color: theme.primary,
                        steps: steps(for: "AM"),
                        isDone: vm.isDone(_:),
                        toggle: vm.toggle
                    )
                    RoutineCardMR(
                        title: "Wind Down",
                        icon: "moon",
                        time: pmTimeString,
                        color: theme.primary,
                        steps: steps(for: "PM"),
                        isDone: vm.isDone(_:),
                        toggle: vm.toggle
                    )
                }
                .padding(.horizontal)

                // Reminder controls
                GroupBox("Reminders") {
                    VStack(alignment: .leading) {
                        Toggle("Enable AM reminder", isOn: Binding(
                            get: { vm.notif.enableAM },
                            set: { vm.notif.enableAM = $0; Task { await vm.applyNotificationPrefs(vm.notif) } }
                        ))
                        DatePicker("AM time",
                                   selection: Binding<Date>(
                                    get: { dateFrom(hour: vm.notif.amHour, minute: vm.notif.amMinute) },
                                    set: { d in
                                        let c = Calendar.current.dateComponents([.hour,.minute], from: d)
                                        vm.notif.amHour = c.hour ?? 7
                                        vm.notif.amMinute = c.minute ?? 30
                                        Task { await vm.applyNotificationPrefs(vm.notif) }
                                    }),
                                   displayedComponents: .hourAndMinute)
                        .disabled(!vm.notif.enableAM)

                        Divider().padding(.vertical, 6)

                        Toggle("Enable PM reminder", isOn: Binding(
                            get: { vm.notif.enablePM },
                            set: { vm.notif.enablePM = $0; Task { await vm.applyNotificationPrefs(vm.notif) } }
                        ))
                        DatePicker("PM time",
                                   selection: Binding<Date>(
                                    get: { dateFrom(hour: vm.notif.pmHour, minute: vm.notif.pmMinute) },
                                    set: { d in
                                        let c = Calendar.current.dateComponents([.hour,.minute], from: d)
                                        vm.notif.pmHour = c.hour ?? 21
                                        vm.notif.pmMinute = c.minute ?? 0
                                        Task { await vm.applyNotificationPrefs(vm.notif) }
                                    }),
                                   displayedComponents: .hourAndMinute)
                        .disabled(!vm.notif.enablePM)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .onAppear { vm.load() }
        .navigationTitle("Routine")
    }

    // MARK: Helpers

    private func steps(for title: String) -> [(slot: RoutineSlot, productName: String?)] {
        guard let routine = vm.routines.first(where: { $0.title.lowercased() == title.lowercased() }) else { return [] }
        return routine.slots.map { slot in
            let name = slot.productID.flatMap { vm.productsByID[$0]?.name }
            return (slot, name)
        }
    }

    private var amTimeString: String {
        timeFormatter.string(from: dateFrom(hour: vm.notif.amHour, minute: vm.notif.amMinute))
    }
    private var pmTimeString: String {
        timeFormatter.string(from: dateFrom(hour: vm.notif.pmHour, minute: vm.notif.pmMinute))
    }
    private var timeFormatter: DateFormatter {
        let df = DateFormatter(); df.timeStyle = .short; return df
    }
    private func dateFrom(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
    private func moveDay(_ delta: Int) {
        let cal = Calendar.current
        vm.selectedDate = cal.date(byAdding: .day, value: delta, to: vm.selectedDate) ?? vm.selectedDate
    }
}

// Compact weekly strip (unique names to avoid collisions)
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

// Routine card (unique names)
private struct RoutineCardMR: View {
    let title: String
    let icon: String
    let time: String
    let color: Color
    let steps: [(slot: RoutineSlot, productName: String?)]
    var isDone: (UUID) -> Bool
    var toggle: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon).font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
            }
            Text(time).foregroundStyle(.secondary)
            ForEach(steps, id: \.slot.id) { pair in
                HStack(spacing: 12) {
                    Button {
                        toggle(pair.slot.id)
                    } label: {
                        Image(systemName: isDone(pair.slot.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isDone(pair.slot.id) ? color : .secondary)
                    }
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
