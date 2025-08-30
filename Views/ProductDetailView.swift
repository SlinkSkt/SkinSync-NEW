// Views/ProductDetailView.swift
import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let theme: AppTheme

    @EnvironmentObject private var routineVM: RoutineViewModel
    @State private var showingAssign = false

    // Index-based selections (rock-solid; no invalid tag warnings)
    @State private var routineIndex: Int = 0
    @State private var slotIndex: Int = 0

    // Ensure indices are always valid
    private func clampSelections() {
        let rc = routineVM.routines.count
        if rc == 0 {
            routineIndex = 0
            slotIndex = 0
            return
        }
        if routineIndex < 0 || routineIndex >= rc { routineIndex = 0 }

        let sc = routineVM.routines[routineIndex].slots.count
        if sc == 0 {
            slotIndex = 0
        } else if slotIndex < 0 || slotIndex >= sc {
            slotIndex = 0
        }
    }

    // Prefill to first routine/slot for convenience
    private func prefillIfNeeded() {
        if routineVM.routines.isEmpty { return }
        if routineIndex < 0 || routineIndex >= routineVM.routines.count { routineIndex = 0 }
        if slotIndex < 0 || slotIndex >= routineVM.routines[routineIndex].slots.count { slotIndex = 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(product.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(product.name)
                    .font(.title.bold())
                Text(product.brand)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                if let r = product.rating {
                    Label(String(format: "%.1f ★", r), systemImage: "star.fill")
                }

                Divider()

                Text("Ingredients")
                    .font(.headline)
                IngredientCloud(ingredients: product.ingredients)
                    .tint(theme.primary)

                Divider()

                Text("Addresses")
                    .font(.headline)
                HStack {
                    ForEach(product.concerns) { c in
                        Text(c.title)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.primary.opacity(0.15))
                            .foregroundStyle(theme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Product")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Make sure routines exist, then clamp the indices
                    if routineVM.routines.isEmpty {
                        Task {
                            await routineVM.ensureDefaultRoutinesIfNeeded()
                            clampSelections()
                            showingAssign = true
                        }
                    } else {
                        clampSelections()
                        showingAssign = true
                    }
                } label: {
                    Label("Add to Routine", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAssign) {
            NavigationStack {
                Form {
                    if routineVM.routines.isEmpty {
                        Section {
                            Text("No routines found. Create default AM/PM routines first, then assign this product to a step.")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                        Section {
                            Button {
                                Task {
                                    await routineVM.ensureDefaultRoutinesIfNeeded()
                                    clampSelections()
                                }
                            } label: {
                                Label("Create AM & PM routines", systemImage: "calendar.badge.plus")
                            }
                        }
                    } else {
                        Section("Choose Routine") {
                            Picker("Routine", selection: $routineIndex) {
                                ForEach(routineVM.routines.indices, id: \.self) { i in
                                    Text(routineVM.routines[i].title).tag(i)
                                }
                            }
                            .onChange(of: routineIndex) { _, _ in
                                // When routine changes, reset slot to first available
                                slotIndex = 0
                                clampSelections()
                            }
                        }

                        Section("Choose Step") {
                            let routines = routineVM.routines
                            if routineIndex < routines.count {
                                let slots = routines[routineIndex].slots
                                Picker("Step", selection: $slotIndex) {
                                    ForEach(slots.indices, id: \.self) { j in
                                        Text(slots[j].step).tag(j)
                                    }
                                }
                            } else {
                                // If routines changed and routineIndex became invalid, reset safely
                                Text("No steps available").foregroundStyle(.secondary)
                            }
                        }
                        
                    }
                }
                .navigationTitle("Add to Routine")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAssign = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            guard !routineVM.routines.isEmpty else { return }
                            let routine = routineVM.routines[routineIndex]
                            guard !routine.slots.isEmpty else { return }
                            let slot = routine.slots[slotIndex]
                            routineVM.set(product: product, for: routine.id, slotID: slot.id)
                            showingAssign = false
                        }
                        .disabled(routineVM.routines.isEmpty ||
                                  routineVM.routines[routineIndex].slots.isEmpty)
                    }
                }
                .onAppear {
                    prefillIfNeeded()
                    clampSelections()
                }
                .onChange(of: routineVM.routines) { _, _ in
                    clampSelections()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            prefillIfNeeded()
            clampSelections()
        }
    }
}
