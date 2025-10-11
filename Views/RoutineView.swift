import SwiftUI
import UniformTypeIdentifiers

struct RoutineView: View {
    @StateObject private var viewModel: RoutineViewModel
    @EnvironmentObject private var productsVM: ProductsViewModel
    @State private var showingAddToMorning = false
    @State private var showingAddToEvening = false
    @State private var deletedProduct: Product?
    @State private var deletedFromMorning = false
    @State private var showUndoToast = false
    @State private var selectedProduct: Product? = nil
    @State private var draggedProduct: Product? = nil
    @State private var isAnyItemDragging = false
    @State private var draggingID: String? = nil
    
    let theme: AppTheme
    let store: DataStore
    let productRepository: ProductRepository?
    
    init(theme: AppTheme, store: DataStore, productRepository: ProductRepository?) {
        self.theme = theme
        self.store = store
        self.productRepository = productRepository
        self._viewModel = StateObject(wrappedValue: RoutineViewModel(store: store, productRepository: productRepository))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // Morning Routine Section
                    MorningRoutineSection(
                        products: viewModel.morning,
                        theme: theme,
                        onAddProduct: { showingAddToMorning = true },
                        onMoveProducts: viewModel.moveMorning,
                        onRemoveProduct: { product in
                            viewModel.removeFromMorning(product)
                            deletedProduct = product
                            deletedFromMorning = true
                            showUndoToast = true
                        },
                        onProductTap: { product in
                            selectedProduct = product
                        },
                        draggedProduct: draggedProduct
                    )
                    
                    // Evening Routine Section
                    EveningRoutineSection(
                        products: viewModel.evening,
                        theme: theme,
                        onAddProduct: { showingAddToEvening = true },
                        onMoveProducts: viewModel.moveEvening,
                        onRemoveProduct: { product in
                            viewModel.removeFromEvening(product)
                            deletedProduct = product
                            deletedFromMorning = false
                            showUndoToast = true
                        },
                        onProductTap: { product in
                            selectedProduct = product
                        },
                        draggedProduct: draggedProduct
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .scrollDisabled(isAnyItemDragging)
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
            .navigationTitle("My Routine")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.load()
                }
            }
            .overlay(alignment: .bottom) {
                // Undo Toast
                if showUndoToast {
                    UndoToastView(
                        message: "Removed from \(deletedFromMorning ? "Morning" : "Evening")",
                        onUndo: {
                            if let product = deletedProduct {
                                if deletedFromMorning {
                                    viewModel.addToMorning(product)
                                } else {
                                    viewModel.addToEvening(product)
                                }
                            }
                            showUndoToast = false
                            deletedProduct = nil
                        },
                        onDismiss: {
                            showUndoToast = false
                            deletedProduct = nil
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showUndoToast)
                }
            }
        }
        .sheet(isPresented: $showingAddToMorning) {
            AddProductSheet(
                title: "Add to Morning Routine",
                icon: "sun.max.fill",
                theme: theme,
                productsVM: productsVM,
                routineVM: viewModel,
                isProductInRoutine: viewModel.isProductInMorning,
                onAddProduct: viewModel.addToMorning
            )
        }
        .sheet(isPresented: $showingAddToEvening) {
            AddProductSheet(
                title: "Add to Evening Routine",
                icon: "moon.stars.fill",
                theme: theme,
                productsVM: productsVM,
                routineVM: viewModel,
                isProductInRoutine: viewModel.isProductInEvening,
                onAddProduct: viewModel.addToEvening
            )
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(
                product: product,
                theme: theme,
                store: store,
                productRepository: productRepository
            )
        }
    }
}

// MARK: - Morning Routine Section
struct MorningRoutineSection: View {
    let products: [Product]
    let theme: AppTheme
    let onAddProduct: () -> Void
    let onMoveProducts: (IndexSet, Int) -> Void
    let onRemoveProduct: (Product) -> Void
    let onProductTap: (Product) -> Void
    let draggedProduct: Product?
    
    var body: some View {
        RoutineSectionCard(
            title: "Morning Routine",
            icon: "sun.max.fill",
            iconColor: .orange,
            products: products,
            theme: theme,
            onAddProduct: onAddProduct,
            onMoveProducts: onMoveProducts,
            onRemoveProduct: onRemoveProduct,
            onProductTap: onProductTap,
            draggedProduct: draggedProduct
        )
    }
}

// MARK: - Evening Routine Section
struct EveningRoutineSection: View {
    let products: [Product]
    let theme: AppTheme
    let onAddProduct: () -> Void
    let onMoveProducts: (IndexSet, Int) -> Void
    let onRemoveProduct: (Product) -> Void
    let onProductTap: (Product) -> Void
    let draggedProduct: Product?
    
    var body: some View {
        RoutineSectionCard(
            title: "Evening Routine",
            icon: "moon.stars.fill",
            iconColor: .purple,
            products: products,
            theme: theme,
            onAddProduct: onAddProduct,
            onMoveProducts: onMoveProducts,
            onRemoveProduct: onRemoveProduct,
            onProductTap: onProductTap,
            draggedProduct: draggedProduct
        )
    }
}

// MARK: - Routine Section Card
struct RoutineSectionCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let products: [Product]
    let theme: AppTheme
    let onAddProduct: () -> Void
    let onMoveProducts: (IndexSet, Int) -> Void
    let onRemoveProduct: (Product) -> Void
    let onProductTap: (Product) -> Void
    let draggedProduct: Product?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("\(products.count) products")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onAddProduct) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityLabel("Add product to \(title)")
                .accessibilityHint("Tap to search and add products to this routine")
            }
            
            // Products List or Empty State
            if products.isEmpty {
                EmptyRoutineView(
                    title: "No products in this routine",
                    icon: icon,
                    iconColor: iconColor,
                    onAddProduct: onAddProduct
                )
            } else {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                        SimpleProductCard(
                                product: product,
                                theme: theme,
                            onDelete: { onRemoveProduct(product) },
                            onTap: { onProductTap(product) },
                            draggingID: draggedProduct?.id.uuidString
                        )
                        .overlay(
                            VStack(spacing: 0) {
                                // TOP drop zone (insert before current row)
                                Rectangle().fill(Color.clear).frame(height: 20)
                                    .background(Color.white.opacity(0.001))
                                    .dropDestination(for: String.self) { items, location in
                                        guard let sourceID = items.first,
                                              let sourceIndex = products.firstIndex(where: { $0.id.uuidString == sourceID }) else { 
                                            return false 
                                        }
                                        
                                        onMoveProducts(IndexSet(integer: sourceIndex), index)
                                        return true
                                    } isTargeted: { _ in }
                                
                                Spacer(minLength: 0)
                                
                                // BOTTOM drop zone (insert after current row)
                                Rectangle().fill(Color.clear).frame(height: 20)
                                    .background(Color.white.opacity(0.001))
                                    .dropDestination(for: String.self) { items, location in
                                        guard let sourceID = items.first,
                                              let sourceIndex = products.firstIndex(where: { $0.id.uuidString == sourceID }) else { 
                                            return false 
                                        }
                                        
                                        onMoveProducts(IndexSet(integer: sourceIndex), index + 1)
                                        return true
                                    } isTargeted: { _ in }
                            }
                        )
                    }
                    
                    // Accept drops at end of list (append)
                    Rectangle().fill(.clear).frame(height: 1)
                        .background(Color.white.opacity(0.001))
                        .dropDestination(for: String.self) { items, location in
                            guard let sourceID = items.first,
                                  let sourceIndex = products.firstIndex(where: { $0.id.uuidString == sourceID }) else { 
                                return false 
                            }
                            
                            onMoveProducts(IndexSet(integer: sourceIndex), products.count)
                            return true
                        } isTargeted: { _ in }
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
                .background(
                    LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Simple Product Card
struct SimpleProductCard: View {
    let product: Product
    let theme: AppTheme
    let onDelete: () -> Void
    let onTap: () -> Void
    let draggingID: String?
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tertiary)
                .opacity(draggingID == product.id.uuidString ? 1.0 : 0.6)
            
            // Product Image
            AssetOrRemoteImage(
                assetName: product.assetName,
                imageURL: product.imageURL
            )
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Product Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(product.brand)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.red)
        }
            .accessibilityLabel("Delete \(product.name)")
        }
        .contentShape(Rectangle())
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .zIndex(draggingID == product.id.uuidString ? 1000 : 0)
        .draggable(product.id.uuidString)
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.brand) \(product.name)")
        .accessibilityHint("Tap to view product details, drag to reorder")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Empty Routine View
struct EmptyRoutineView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let onAddProduct: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
        ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .fill(iconColor.opacity(0.2))
                    .frame(height: 120)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(iconColor.opacity(0.6))
                    
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onAddProduct) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add products")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Add products to routine")
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - Undo Toast View
struct UndoToastView: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button("Undo", action: onUndo)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, AppTheme.Spacing.screenEdge)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}

// MARK: - Add Product Sheet
struct AddProductSheet: View {
    let title: String
    let icon: String
    let theme: AppTheme
    let productsVM: ProductsViewModel
    let routineVM: RoutineViewModel
    let isProductInRoutine: (Product) -> Bool
    let onAddProduct: (Product) -> Void
    
    @State private var searchQuery = ""
    @State private var searchResults: [Product] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMoreResults = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search products...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onChange(of: searchQuery) { _, newValue in
                            searchProducts(query: newValue)
                        }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                
                // Results
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, AppTheme.Spacing.xl)
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    ContentStateView(
                        icon: "magnifyingglass",
                        title: "No products found",
                        message: "Try searching with different terms"
                    )
                    .padding(.top, AppTheme.Spacing.xl)
                } else if searchResults.isEmpty {
                    ContentStateView(
                        icon: "magnifyingglass",
                        title: "Search for products",
                        message: "Type in the search field to find products to add"
                    )
                    .padding(.top, AppTheme.Spacing.xl)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, product in
                                AddProductRow(
                                    product: product,
                                    isInRoutine: isProductInRoutine(product),
                                    onAdd: { 
                                        onAddProduct(product)
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                                )
                                .onAppear {
                                    if index >= searchResults.count - 3 && hasMoreResults && !isLoadingMore {
                                        loadMoreResults()
                                    }
                                }
                            }
                            
                            if isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading more...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, AppTheme.Spacing.md)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenEdge)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    private func searchProducts(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            currentPage = 1
            hasMoreResults = true
            return
        }
        
        isLoading = true
        currentPage = 1
        hasMoreResults = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if query == searchQuery {
                Task {
                    await searchProductsAPI(query: query, page: 1)
                }
            }
        }
    }
    
    private func searchProductsAPI(query: String, page: Int) async {
        productsVM.query = query
        await productsVM.searchOnline()
        
        if page == 1 {
            searchResults = productsVM.searchResults
        } else {
            searchResults.append(contentsOf: productsVM.searchResults)
        }
        
        hasMoreResults = productsVM.searchResults.count >= 20
        isLoading = false
        isLoadingMore = false
    }
    
    private func loadMoreResults() {
        guard !searchQuery.isEmpty && hasMoreResults && !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            await searchProductsAPI(query: searchQuery, page: currentPage)
        }
    }
}

// MARK: - Add Product Row
struct AddProductRow: View {
    let product: Product
    let isInRoutine: Bool
    let onAdd: () -> Void
    
    @State private var isAdding = false
    @State private var showSuccess = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Product Image
            AssetOrRemoteImage(
                assetName: product.assetName,
                imageURL: product.imageURL
            )
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Product Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(product.brand)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Add Button
            Button(action: {
                guard !isInRoutine && !isAdding else { return }
                
                isAdding = true
                onAdd()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSuccess = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSuccess = false
                        isAdding = false
                    }
                }
            }) {
                HStack(spacing: 6) {
                    if isAdding && !showSuccess {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    
                    Text(showSuccess ? "Added!" : (isInRoutine ? "Added" : "Add"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(showSuccess ? .green : (isInRoutine ? .secondary : Color.white))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(showSuccess ? Color.green.opacity(0.12) : (isInRoutine ? Color(.systemGray5) : Color.blue))
                        .overlay(
                            Capsule()
                                .stroke(showSuccess ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: (isInRoutine || showSuccess) ? Color.clear : Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                )
            }
            .disabled(isInRoutine || isAdding)
            .accessibilityLabel(isInRoutine ? "Already added" : "Add to routine")
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    RoutineView(
        theme: AppTheme(config: .default),
        store: FileDataStore(),
        productRepository: nil
    )
    .environmentObject(ProductsViewModel(store: FileDataStore(), productRepository: nil))
}