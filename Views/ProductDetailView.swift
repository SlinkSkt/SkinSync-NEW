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
            LazyVStack(spacing: AppTheme.Spacing.xl) {
                // Product header image
                VStack(spacing: 0) {
                    Image(product.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipped()
                    
                    // Gradient overlay for better typography
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    .offset(y: -80)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                // Product info section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(product.name)
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(product.brand)
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(.secondary)
                        
                        if let rating = product.rating {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                            .foregroundStyle(.yellow)
                                            .font(.caption)
                                    }
                                }
                                Text(String(format: "%.1f", rating))
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)

                // Ingredients section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Label("Key Ingredients", systemImage: "sparkles")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)
                    
                    if !product.ingredients.isEmpty {
                        IngredientCloud(ingredients: product.ingredients)
                            .tint(theme.primary)
                    } else {
                        Text("No ingredient information available")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal, AppTheme.Spacing.md)

                // Targets section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Label("Target Concerns", systemImage: "target")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(.primary)
                    
                    if !product.concerns.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(product.concerns) { concern in
                                    Text(concern.title)
                                        .font(AppTheme.Typography.subheadline)
                                        .padding(.horizontal, AppTheme.Spacing.md)
                                        .padding(.vertical, AppTheme.Spacing.sm)
                                        .background(theme.primary.opacity(0.15))
                                        .foregroundStyle(theme.primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xs)
                        }
                    } else {
                        Text("No concern information available")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                Spacer(minLength: AppTheme.Spacing.xl)
            }
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Ensure routines exist, then clamp and present
                    if routines.isEmpty {
                        routineVM.ensureDefaultRoutinesIfNeeded()
                        clampSelections()
                        showingAssign = true
                    } else {
                        clampSelections()
                        showingAssign = true
                    }
                } label: {
                    Label("Add to Routine", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(theme.primary, in: Capsule())
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
