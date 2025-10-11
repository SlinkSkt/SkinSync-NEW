// Views/ProductDetailView.swift
import SwiftUI

struct ProductDetailView: View {
    let product: Product?
    let barcode: String?
    let theme: AppTheme

    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var productsVM: ProductsViewModel
    @EnvironmentObject private var routineVM: RoutineViewModel
    @State private var showingAssign = false
    @State private var routineIndex: Int = 0
    @State private var slotIndex: Int = 0

    init(product: Product, theme: AppTheme, store: DataStore, productRepository: ProductRepository? = nil) {
        self.product = product
        self.barcode = nil
        self.theme = theme
        self._viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product, store: store, productRepository: productRepository))
    }
    
    init(barcode: String, theme: AppTheme, store: DataStore, productRepository: ProductRepository? = nil) {
        self.product = nil
        self.barcode = barcode
        self.theme = theme
        self._viewModel = StateObject(wrappedValue: ProductDetailViewModel(barcode: barcode, store: store, productRepository: productRepository))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ContentStateView(
                    icon: "magnifyingglass",
                    title: "Loading Product",
                    message: barcode != nil ? "Fetching product information..." : "Loading product details..."
                )
            } else if let error = viewModel.error {
                ContentStateView(
                    icon: "exclamationmark.triangle",
                    title: "Error",
                    message: error.localizedDescription
                )
            } else if let product = viewModel.product {
                productDetailContent(product: product)
            } else {
                ContentStateView(
                    icon: "questionmark.circle",
                    title: "Product Not Found",
                    message: barcode != nil ? "No product found for barcode: \(barcode!)" : "Product information unavailable"
                )
            }
        }
        .navigationTitle(viewModel.product?.name ?? "Product")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let product = viewModel.product {
                    FavoriteHeartButton(
                        isOn: productsVM.isFavorite(product),
                        action: { productsVM.toggleFavorite(product) }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func productDetailContent(product: Product) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.xl) {
                // Hero Section
                HeroSection(product: product, theme: theme, isFavorite: productsVM.isFavorite(product)) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        productsVM.toggleFavorite(product)
                    }
                }
                
                // Product Overview
                ProductOverviewSection(product: product, theme: theme)
                
                // Nutrition & Environmental Info
                if product.nutritionGrade != nil || product.isFromOpenBeautyFacts {
                    NutritionSection(product: product, theme: theme)
                }
                
                // Categories & Labels
                if (product.productCategories?.isEmpty == false) || 
                   (product.productLabels?.isEmpty == false) {
                    CategoriesLabelsSection(product: product, theme: theme)
                }
                
                // Ingredients Section
                IngredientsSection(
                    parsedIngredients: viewModel.parsedIngredients,
                    theme: theme,
                    onIngredientTap: viewModel.showIngredientDetails
                )
                
                // Allergens & Traces
                if (product.allergens?.isEmpty == false) || 
                   (product.traces?.isEmpty == false) {
                    AllergensTracesSection(product: product, theme: theme)
                }
                
                // Additives
                if let additives = product.additives, !additives.isEmpty {
                    AdditivesSection(product: product, theme: theme)
                }
                
                // Product Details Footer
                ProductDetailsFooter(product: product, theme: theme)
                
                Spacer(minLength: AppTheme.Spacing.xxl)
            }
            .padding(.horizontal, AppTheme.Spacing.screenEdge)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(
                    LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemBackground).opacity(0.8)
                ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAssign = true
                } label: {
                    Label("Add to Routine", systemImage: "plus.circle.fill")
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(theme.primary, in: Capsule())
                        .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Add to Routine")
                .accessibilityHint("Add this product to your skincare routine")
            }
        }
        .sheet(isPresented: $viewModel.showingIngredientSheet) {
            IngredientDetailSheet(
                ingredient: viewModel.selectedIngredient,
                theme: theme
            )
        }
        .sheet(isPresented: $showingAssign) {
            if let product = viewModel.product {
                RoutineAssignmentSheet(
                    product: product,
                    routineVM: routineVM,
                    isPresented: $showingAssign
                )
            }
        }
    }
}

// MARK: - Hero Section

private struct HeroSection: View {
    let product: Product
    let theme: AppTheme
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Enhanced Product Image with Premium Overlays
            ZStack {
                // Product Image with adaptive sizing and premium styling
                ProductImage(
                    imageName: product.imageName,
                    assetName: product.assetName,
                    imageURL: product.imageURL
                )
                .frame(maxHeight: 380) // Maximum height, but adapts to image aspect ratio
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.11), radius: 22, x: 0, y: 11)
                
                // Top-left: Rating Badge with enhanced styling for larger image
                VStack {
                    HStack {
                        if let rating = product.rating {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(AppTheme.Spacing.xl)
                
                // Top-right: Enhanced Favorite Button for larger image
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onFavoriteToggle) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 56, height: 56) // Larger for bigger image
                                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                                
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 24, weight: .semibold)) // Larger icon
                                    .foregroundStyle(isFavorite ? .pink : .white)
                            }
                        }
                        .scaleEffect(isFavorite ? 1.15 : 1.0) // Slightly larger scale
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFavorite)
                    }
                    Spacer()
                }
                .padding(AppTheme.Spacing.xl)
            }
            
            // Enhanced Product Info
            VStack(spacing: AppTheme.Spacing.lg) {
                // Product Name with premium typography
                        Text(product.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                        
                // Brand with enhanced styling
                        Text(product.brand)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Enhanced Category Badge
                Text(product.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.1), theme.primary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: theme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95),
                    Color(.secondarySystemBackground).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.brand) \(product.name)")
    }
}

// MARK: - Product Image

private struct ProductImage: View {
    let imageName: String?
    let assetName: String
    let imageURL: String?

    var body: some View {
        ZStack {
            // Background that adapts to image size
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            // Product image - prioritize remote URL, then local assets
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFit() // Show complete image without cropping
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                } placeholder: {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            } else if let imageName = imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit() // Show complete image without cropping
                    .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
            } else if !assetName.isEmpty {
                Image(assetName)
                    .resizable()
                    .scaledToFit() // Show complete image without cropping
                    .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
            } else {
                Image(systemName: "cube.box.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                            .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Meta Chips Section

private struct MetaChipsSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Product Details")
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                // Category Chip
                MetaChip(
                    title: "Category",
                    value: product.category,
                    icon: "folder.fill",
                    color: theme.primary
                )
                
                // Size/Quantity Chip (if available)
                if let productQuantity = product.quantity {
                    MetaChip(
                        title: "Size",
                        value: productQuantity,
                        icon: "ruler",
                        color: .blue
                    )
                }
                
                // Labels Chip (if available)
                if let labels = product.productLabels, !labels.isEmpty {
                    MetaChip(
                        title: "Labels",
                        value: labels.prefix(2).joined(separator: ", "),
                        icon: "tag.fill",
                        color: .green
                    )
                }
                
                // Barcode Chip
                MetaChip(
                    title: "Barcode",
                    value: product.barcode,
                    icon: "barcode",
                    color: .gray
                )
                
                // Rating Chip (if available)
                        if let rating = product.rating {
                    MetaChip(
                        title: "Rating",
                        value: String(format: "%.1f/5", rating),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Meta Chip

private struct MetaChip: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(Color(.quaternaryLabel).opacity(0.2), in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Ingredients Section

private struct IngredientsSection: View {
    let parsedIngredients: ParsedIngredients
    let theme: AppTheme
    let onIngredientTap: (Ingredient) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Ingredients")
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            if parsedIngredients.hasIngredients {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Active Ingredients
                    if !parsedIngredients.activeIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Active Ingredients")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("\(parsedIngredients.activeIngredients.count)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(theme.primary.opacity(0.15), in: Capsule())
                            }
                            
                            DetailIngredientCloud(
                                ingredients: parsedIngredients.activeIngredients,
                                isActive: true,
                                theme: theme,
                                onTap: onIngredientTap
                            )
                        }
                    }
                    
                    // Other Ingredients
                    if !parsedIngredients.otherIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Other Ingredients")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("\(parsedIngredients.otherIngredients.count)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(Color(.quaternaryLabel).opacity(0.3), in: Capsule())
                            }
                            
                            DetailIngredientCloud(
                                ingredients: parsedIngredients.otherIngredients,
                                isActive: false,
                                theme: theme,
                                onTap: onIngredientTap
                            )
                        }
                    }
                }
                    } else {
                        Text("No ingredient information available")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(AppTheme.Spacing.lg)
                    }
                }
                .padding(AppTheme.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Enhanced Ingredient Cloud

private struct DetailIngredientCloud: View {
    let ingredients: [Ingredient]
    let isActive: Bool
    let theme: AppTheme
    let onTap: (Ingredient) -> Void
    
    var body: some View {
        IngredientCloudLayout(spacing: AppTheme.Spacing.sm, rowSpacing: AppTheme.Spacing.sm) {
            ForEach(ingredients) { ingredient in
                Button {
                    onTap(ingredient)
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(ingredient.commonName)
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                        
                        if isActive {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(theme.primary)
                        }
                    }
                                        .padding(.horizontal, AppTheme.Spacing.md)
                                        .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        isActive ? theme.primary.opacity(0.15) : Color(.quaternaryLabel).opacity(0.2),
                        in: Capsule()
                    )
                    .foregroundStyle(isActive ? theme.primary : .primary)
                                        .overlay(
                                            Capsule()
                            .stroke(
                                isActive ? theme.primary.opacity(0.3) : Color(.quaternaryLabel).opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(ingredient.commonName)\(isActive ? ", Active ingredient" : "")")
                .accessibilityHint("Tap to view ingredient details")
            }
        }
    }
}

// MARK: - Footer Section

private struct FooterSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Divider()
                .foregroundStyle(Color(.quaternaryLabel))
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Product Information")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text("Barcode: \(product.barcode)")
                    .font(AppTheme.Typography.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                if product.isFromOpenBeautyFacts {
                    Text("Data from Open Beauty Facts")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }
                
                if let lastModified = product.lastModified {
                    Text("Last updated: \(lastModified.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }
}

// MARK: - Ingredient Detail Sheet

private struct IngredientDetailSheet: View {
    let ingredient: Ingredient?
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if let ingredient = ingredient {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            Text(ingredient.commonName)
                                .font(AppTheme.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(ingredient.inciName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                Text("Role")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(ingredient.role)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.lg)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                            
                            if let note = ingredient.note {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Text("Benefits")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(note)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AppTheme.Spacing.lg)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                            }
                        }
                        .padding(AppTheme.Spacing.screenEdge)
                    }
                }
            }
            .navigationTitle("Ingredient Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Routine Assignment Sheet

private struct RoutineAssignmentSheet: View {
    let product: Product
    @ObservedObject var routineVM: RoutineViewModel
    @Binding var isPresented: Bool
    @State private var selectedRoutine: RoutineType = .morning
    
    enum RoutineType: String, CaseIterable {
        case morning = "Morning"
        case evening = "Evening"
    }
    
    var body: some View {
            NavigationStack {
                Form {
                Section("Choose Routine") {
                    Picker("Routine", selection: $selectedRoutine) {
                        ForEach(RoutineType.allCases, id: \.self) { routine in
                            Text(routine.rawValue).tag(routine)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Product Info") {
                    HStack {
                        ProductImage(
                            imageName: product.imageName,
                            assetName: product.assetName,
                            imageURL: product.imageURL
                        )
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 16, weight: .semibold))
                            Text(product.brand)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Section("Current Products") {
                    let currentProducts = selectedRoutine == .morning ? routineVM.morning : routineVM.evening
                    
                    if currentProducts.isEmpty {
                        Text("No products in \(selectedRoutine.rawValue.lowercased()) routine")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(currentProducts) { product in
                            HStack {
                                ProductImage(
                                    imageName: product.imageName,
                                    assetName: product.assetName,
                                    imageURL: product.imageURL
                                )
                                .frame(width: 30, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                Text(product.name)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Spacer()
                            }
                            }
                        }
                    }
                }
                .navigationTitle("Add to Routine")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                        if selectedRoutine == .morning {
                            routineVM.addToMorning(product)
                        } else {
                            routineVM.addToEvening(product)
                        }
                        isPresented = false
                    }
                    .disabled(routineVM.isProductInAnyRoutine(product))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Favorite Heart Button (Reused from ProductsScreen)

// Note: FavoriteHeartButton is defined in ProductsScreen.swift

// MARK: - Product Overview Section

private struct ProductOverviewSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Product Information", icon: "info.circle")
            
            VStack(spacing: AppTheme.Spacing.sm) {
                InfoRow(label: "Brand", value: product.brand)
                InfoRow(label: "Category", value: product.category)
                if let quantity = product.quantity {
                    InfoRow(label: "Size", value: quantity)
                }
                InfoRow(label: "Barcode", value: product.barcode, isMonospaced: true)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Nutrition Section

private struct NutritionSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Nutrition & Environmental", icon: "leaf")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                if let nutritionGrade = product.nutritionGrade {
                    GradeCard(title: "Nutrition Grade", grade: nutritionGrade, color: gradeColor(nutritionGrade))
                }
                
                if product.isFromOpenBeautyFacts {
                    InfoCard(title: "Data Source", value: "Open Beauty Facts", icon: "globe")
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A": return .green
        case "B": return .mint
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default: return .gray
        }
    }
}

// MARK: - Categories & Labels Section

private struct CategoriesLabelsSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Categories & Labels", icon: "tag")
            
            VStack(spacing: AppTheme.Spacing.md) {
                if let categories = product.productCategories, !categories.isEmpty {
                    ChipSection(title: "Categories", chips: categories, color: theme.primary)
                }
                
                if let labels = product.productLabels, !labels.isEmpty {
                    ChipSection(title: "Labels", chips: labels, color: .blue)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Allergens & Traces Section

private struct AllergensTracesSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Allergens & Traces", icon: "exclamationmark.triangle")
            
            VStack(spacing: AppTheme.Spacing.md) {
                if let allergens = product.allergens, !allergens.isEmpty {
                    ChipSection(title: "Allergens", chips: allergens, color: .red)
                }
                
                if let traces = product.traces, !traces.isEmpty {
                    ChipSection(title: "May Contain Traces", chips: traces, color: .orange)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Additives Section

private struct AdditivesSection: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Food Additives", icon: "plus.circle")
            
            if let additives = product.additives, !additives.isEmpty {
                ChipSection(title: "Additives", chips: additives, color: .purple)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Product Details Footer

private struct ProductDetailsFooter: View {
    let product: Product
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Product Details", icon: "info")
            
            VStack(spacing: AppTheme.Spacing.sm) {
                if let lastModified = product.lastModified {
                    InfoRow(label: "Last Updated", value: DateFormatter.shortDate.string(from: lastModified))
                }
                
                if let createdDate = product.createdDate {
                    InfoRow(label: "Added to Database", value: DateFormatter.shortDate.string(from: createdDate))
                }
                
                InfoRow(label: "Data Source", value: product.isFromOpenBeautyFacts ? "Open Beauty Facts" : "Local Database")
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Helper Components

private struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.bottom, AppTheme.Spacing.sm)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var isMonospaced: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(isMonospaced ? .system(.body, design: .monospaced) : .system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

private struct ChipSection: View {
    let title: String
    let chips: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            DetailIngredientCloud(
                ingredients: chips.map { Ingredient(inciName: $0, commonName: $0, role: "tag", note: nil) },
                isActive: false,
                theme: AppTheme(config: .default),
                onTap: { _ in }
            )
        }
    }
}

private struct GradeCard: View {
    let title: String
    let grade: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(grade)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1), in: Circle())
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
    }
}

private struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(AppTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
