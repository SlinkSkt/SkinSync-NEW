//
//  RemindersSettingsView.swift
//  SkinSync
//
//  Created by Zhen Xiao on 15/8/2025.
//
import SwiftUI

/// reminders settings screen for AM / PM routine notifications.
/// Uses the NotificationViewModel injected at the app level.
struct RemindersSettingsView: View {
    @EnvironmentObject private var vm: NotificationViewModel

    var body: some View {
        Form {
            Section(header: Text("AM Reminder")) {
                Toggle("Enable AM reminder", isOn: Binding(
                    get: { vm.notif.enableAM },
                    set: { newValue in
                        vm.notif.enableAM = newValue
                        Task { await vm.applyNotificationPrefs(vm.notif) }
                    }
                ))

                DatePicker(
                    "AM time",
                    selection: Binding<Date>(
                        get: { dateFrom(hour: vm.notif.amHour, minute: vm.notif.amMinute) },
                        set: { d in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                            vm.notif.amHour = c.hour ?? 7
                            vm.notif.amMinute = c.minute ?? 30
                            Task { await vm.applyNotificationPrefs(vm.notif) }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .disabled(!vm.notif.enableAM)
            }

            Section(header: Text("PM Reminder")) {
                Toggle("Enable PM reminder", isOn: Binding(
                    get: { vm.notif.enablePM },
                    set: { newValue in
                        vm.notif.enablePM = newValue
                        Task { await vm.applyNotificationPrefs(vm.notif) }
                    }
                ))

                DatePicker(
                    "PM time",
                    selection: Binding<Date>(
                        get: { dateFrom(hour: vm.notif.pmHour, minute: vm.notif.pmMinute) },
                        set: { d in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                            vm.notif.pmHour = c.hour ?? 21
                            vm.notif.pmMinute = c.minute ?? 0
                            Task { await vm.applyNotificationPrefs(vm.notif) }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .disabled(!vm.notif.enablePM)
            }

            if !(vm.notif.enableAM || vm.notif.enablePM) {
                Section {
                    Text("Notifications are turned off. You can enable AM, PM, or both.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Reminders")
    }

    // MARK: - Helpers
    private func dateFrom(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}
