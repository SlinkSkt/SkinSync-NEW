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
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                
                // Header with month + week strip
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Your Routine")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundStyle(.primary)
                            
                            Text(selectedDate, format: .dateTime.year().month(.wide))
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Button { moveDay(-7) } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                            
                            Button { selectedDate = Date() } label: { 
                                Text("Today")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.primary)
                            
                            Button { moveDay(+7) } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    WeekStripMR(
                        theme: theme,
                        days: week(for: selectedDate),
                        selected: selectedDate
                    ) { d in selectedDate = d }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)

                // AM / PM cards
                VStack(spacing: AppTheme.Spacing.lg) {
                    RoutineCardMR_NoTicks(
                        title: "Rise and Shine",
                        icon: "sun.max",
                        time: amTimeString,
                        color: .orange,
                        steps: steps(for: "AM")
                    )
                    RoutineCardMR_NoTicks(
                        title: "Wind Down",
                        icon: "moon.stars",
                        time: pmTimeString,
                        color: .indigo,
                        steps: steps(for: "PM")
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.md)

                // Empty state if there are no routines/slots at all
                if vm.routines.flatMap({ $0.slots }).isEmpty {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        ContentStateView(
                            icon: "calendar.badge.plus",
                            title: "No routine yet",
                            message: "Use the Products tab to add items to AM/PM steps."
                        )
                        
                        Button(action: {}) {
                            Label("Explore Products", systemImage: "cart")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .background(theme.primary, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }

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
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Label("Notification Settings", systemImage: "bell.badge")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Morning Routine")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(amTimeString)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(vm.notif.enableAM ? .primary : .secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: vm.notif.enableAM ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(vm.notif.enableAM ? .green : .secondary)
                                    .font(.title3)
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Evening Routine")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(pmTimeString)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(vm.notif.enablePM ? .primary : .secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: vm.notif.enablePM ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(vm.notif.enablePM ? .green : .secondary)
                                    .font(.title3)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                    .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, AppTheme.Spacing.md)
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

// Weekly strip
private struct WeekStripMR: View {
    let theme: AppTheme
    let days: [Date]
    let selected: Date
    var onSelect: (Date) -> Void

    private let cal = Calendar(identifier: .gregorian)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(days, id: \.self) { day in
                    let isToday = cal.isDateInToday(day)
                    let isSelected = cal.isDate(day, inSameDayAs: selected)
                    
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("\(cal.component(.day, from: day))")
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? theme.primary : .clear)
                                    .strokeBorder(isToday && !isSelected ? theme.primary : .clear, lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? .clear : Color(.quaternaryLabel), lineWidth: 0.5)
                            )
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(day) }
                    .animation(.default, value: selected)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Label(title, systemImage: icon)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)
                        .labelStyle(.titleAndIcon)
                    
                    Text(time)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(.quaternaryLabel))
                    .font(.caption)
            }

            if steps.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color(.quaternaryLabel))
                    
                    Text("No steps configured yet")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(steps, id: \.slot.id) { pair in
                        HStack(spacing: AppTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                
                                Text("\(steps.firstIndex(where: { $0.slot.id == pair.slot.id }) ?? 0) + 1")
                                    .font(AppTheme.Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(color)
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(pair.slot.step)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)
                                
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    Text(pair.productName ?? "No product selected")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    if pair.productName == nil {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(Color(.quaternaryLabel).opacity(0.2), in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
