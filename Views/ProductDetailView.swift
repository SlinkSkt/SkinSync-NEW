// Views/ProductDetailView.swift
import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let theme: AppTheme

    @EnvironmentObject private var routineVM: RoutineViewModel
    @State private var showingAssign = false

    // Index-based selections
    @State private var routineIndex: Int = 0
    @State private var slotIndex: Int = 0

    // MARK: - Safe accessors

    private var routines: [Routine] {
        routineVM.routines
    }

    /// Currently selected routine if the index is valid.
    private var currentRoutine: Routine? {
        guard routineIndex >= 0, routineIndex < routines.count else { return nil }
        return routines[routineIndex]
    }

    /// Slots for the current routine (or empty).
    private var currentSlots: [RoutineSlot] {
        currentRoutine?.slots ?? []
    }

    // Keep indices in range whenever underlying data changes.
    private func clampSelections() {
        if routines.isEmpty {
            routineIndex = 0
            slotIndex = 0
            return
        }
        if routineIndex < 0 || routineIndex >= routines.count {
            routineIndex = 0
        }
        let sc = currentSlots.count
        if sc == 0 {
            slotIndex = 0
        } else if slotIndex < 0 || slotIndex >= sc {
            slotIndex = 0
        }
    }

    // Prefill to first routine/slot
    private func prefillIfNeeded() {
        guard !routines.isEmpty else { return }
        if routineIndex < 0 || routineIndex >= routines.count { routineIndex = 0 }
        if slotIndex < 0 || slotIndex >= currentSlots.count { slotIndex = 0 }
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

                Text("Targets")
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
                    // Ensure routines exist, then clamp and present
                    if routines.isEmpty {
                        // If your ensureDefaultRoutinesIfNeeded() is async, do:
                        // Task { await routineVM.ensureDefaultRoutinesIfNeeded(); clampSelections(); showingAssign = true }
                        routineVM.ensureDefaultRoutinesIfNeeded()
                        clampSelections()
                        showingAssign = true
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
                    if routines.isEmpty {
                        Section {
                            Text("No routines found. Create default AM/PM routines first, then assign this product to a step.")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                        Section {
                            Button {
                                // If async, wrap in Task { await … }
                                routineVM.ensureDefaultRoutinesIfNeeded()
                                clampSelections()
                            } label: {
                                Label("Create AM & PM routines", systemImage: "calendar.badge.plus")
                            }
                        }
                    } else {
                        Section("Choose Routine") {
                            Picker("Routine", selection: $routineIndex) {
                                ForEach(routines.indices, id: \.self) { i in
                                    Text(routines[i].title).tag(i)
                                }
                            }
                            .onChange(of: routineIndex) {
                                // When routine changes, reset slot to first available
                                slotIndex = 0
                                clampSelections()
                            }
                        }

                        Section("Choose Step") {
                            if currentSlots.isEmpty {
                                Text("No steps available").foregroundStyle(.secondary)
                            } else {
                                Picker("Step", selection: $slotIndex) {
                                    ForEach(currentSlots.indices, id: \.self) { j in
                                        Text(currentSlots[j].step).tag(j)
                                    }
                                }
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
                            guard let routine = currentRoutine, !currentSlots.isEmpty else { return }
                            let slot = currentSlots[slotIndex]
                            routineVM.set(product: product, for: routine.id, slotID: slot.id)
                            showingAssign = false
                        }
                        .disabled(currentRoutine == nil || currentSlots.isEmpty)
                    }
                }
                .onAppear {
                    prefillIfNeeded()
                    clampSelections()
                }
                .onChange(of: routines) { _, _ in
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
