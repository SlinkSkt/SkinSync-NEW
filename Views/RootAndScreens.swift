// Views/RootAndScreens.swift
import SwiftUI

// MARK: - Root (5 tabs): Home, Scan, Routine, Products, Profile
struct RootView: View {
    @EnvironmentObject private var app: AppModel

    // Shared dependencies so every view model uses the same store/services
    private let store: FileDataStore
    private let notif: NotificationScheduler
    private let productRepository: ProductRepository
    private let uvService: UVIndexService

    @StateObject private var homeVM: HomeViewModel
    @StateObject private var scanVM: ScanViewModel
    @StateObject private var routineVM: RoutineViewModel
    @StateObject private var notificationVM: NotificationViewModel
    @StateObject private var productsVM: ProductsViewModel
    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var syncAIVM: SyncAIViewModel

    init() {
        let ds = FileDataStore()
        ds.seedIfNeeded() // copy bundled JSON to Documents on first run

        // Create services as locals first (so the app don't read stored properties before init finishes)
        let notifSvc = LocalNotificationScheduler()
        let productRepo = OpenBeautyFactsRepository(store: ds)  // Use new repository
        let uvSvc = OpenUVService()

        // Assign to stored properties
        self.store = ds
        self.notif = notifSvc
        self.productRepository = productRepo
        self.uvService = uvSvc

        // safe to build StateObjects using the local services
        _homeVM = StateObject(wrappedValue: HomeViewModel(store: ds))
        _scanVM = StateObject(wrappedValue: ScanViewModel(productRepository: productRepo,
                                                          store: ds))
        _routineVM = StateObject(wrappedValue: RoutineViewModel(store: ds, productRepository: productRepo))
        _notificationVM = StateObject(wrappedValue: NotificationViewModel(store: ds, scheduler: notifSvc))
        _productsVM = StateObject(wrappedValue: ProductsViewModel(store: ds, productRepository: productRepo))
        _profileVM = StateObject(wrappedValue: ProfileViewModel(store: ds))
        _syncAIVM = StateObject(wrappedValue: SyncAIViewModel())
    }

    private var theme: AppTheme { AppTheme(config: app.config) }

    @State private var selectedTab = 0
    @State private var showTabBar = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        HomeView(theme: theme, uvService: uvService)
                            .environmentObject(homeVM)
                            .environmentObject(profileVM)
                            .environmentObject(productsVM)
                            .environmentObject(notificationVM)
                            .environmentObject(routineVM)
                        .navigationDestination(for: Product.self) { p in
                            ProductDetailView(product: p, theme: theme, store: store, productRepository: productRepository)
                                .environmentObject(productsVM)
                                .onAppear { showTabBar = false }
                                .onDisappear { showTabBar = true }
                        }
                    }
                    .environmentObject(routineVM)
                    
                case 1:
                    NavigationStack {
                        ProductsScreen(theme: theme)
                            .environmentObject(productsVM)
                            .navigationTitle("Products")
                        .navigationDestination(for: Product.self) { p in
                            ProductDetailView(product: p, theme: theme, store: store, productRepository: productRepository)
                                .environmentObject(productsVM)
                                .onAppear { showTabBar = false }
                                .onDisappear { showTabBar = true }
                        }
                    }
                    .environmentObject(routineVM)
                    
                case 2:
                    ScannerPage(theme: theme, store: store, productRepository: productRepository)
                        .environmentObject(scanVM)
                        .environmentObject(productsVM)
                        .environmentObject(routineVM)
                    
                case 3:
                    SyncAIView(theme: theme, viewModel: syncAIVM)
                    
                case 4:
                    RoutineView(theme: theme, store: store, productRepository: productRepository)
                        .environmentObject(productsVM)
                        .environmentObject(routineVM)
                    
                default:
                    EmptyView()
                }
            }
            
            // Custom Tab Bar
            if showTabBar {
                CustomTabBar(selectedTab: $selectedTab, theme: theme)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .tint(theme.primary)
        .onAppear {
            // initial loads
            homeVM.load()
            productsVM.load()
            Task {
                await routineVM.load()
            }
        }
    }
}

// MARK: - Home (latest scan + recommendations)
struct HomeView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var notificationVM: NotificationViewModel
    @EnvironmentObject private var routineVM: RoutineViewModel
    let theme: AppTheme
    let uvService: UVIndexService
    @State private var showingProfile = false
    
    // MARK: - Computed Properties
    
    private var isMorningTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12
    }
    
    private var routineTitle: String {
        isMorningTime ? "Morning Routine" : "Evening Routine"
    }
    
    private var routineIcon: String {
        isMorningTime ? "sun.max.fill" : "moon.fill"
    }
    
    private var routineProducts: [Product] {
        isMorningTime ? routineVM.morning : routineVM.evening
    }
    
    private var timeBasedRoutineSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: routineIcon)
                        .font(.title2)
                        .foregroundStyle(isMorningTime ? theme.success : theme.info)
                        .frame(width: 24, height: 24)
                    
                    Text(routineTitle)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text(isMorningTime ? "Before 12 PM" : "After 12 PM")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        LinearGradient(
                            colors: [isMorningTime ? theme.success.opacity(0.1) : theme.info.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                            .stroke(isMorningTime ? theme.success.opacity(0.3) : theme.info.opacity(0.3), lineWidth: 1)
                    )
            }
            
            if !routineProducts.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("Your \(routineTitle.lowercased()) products")
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(routineProducts.count) product\(routineProducts.count == 1 ? "" : "s")")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            ForEach(routineProducts) { product in
                                NavigationLink(value: product) {
                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        AsyncImage(url: product.imageURL?.isEmpty == false ? URL(string: product.imageURL!) : nil) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            if !product.assetName.isEmpty {
                                                Image(product.assetName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                                .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
                                        )
                                        
                                        VStack(spacing: AppTheme.Spacing.xs) {
                                            Text(product.brand)
                                                .font(AppTheme.Typography.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                            
                                            Text(product.name)
                                                .font(AppTheme.Typography.caption2)
                                                .foregroundStyle(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 90)
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(.systemBackground).opacity(0.8), Color(.systemBackground).opacity(0.4)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                            .stroke(Color(.quaternaryLabel).opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xs)
                    }
                    .padding(.horizontal, -AppTheme.Spacing.xs)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: routineIcon)
                        .font(.title)
                        .foregroundStyle(isMorningTime ? theme.success.opacity(0.6) : theme.info.opacity(0.6))
                        .frame(width: 40, height: 40)
                    
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("No \(routineTitle.lowercased()) products yet")
                            .font(AppTheme.Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Add products to your \(routineTitle.lowercased()) in the Routine tab")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [
                            isMorningTime ? theme.success.opacity(0.05) : theme.info.opacity(0.05),
                            Color(.quaternaryLabel).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(
                            isMorningTime ? theme.success.opacity(0.2) : theme.info.opacity(0.2),
                            lineWidth: 1
                        )
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.section) {
                // Welcome header with profile button
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: profileVM.profile.profileIcon)
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                            .frame(width: 56, height: 56)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityLabel("Open Profile")
                    .accessibilityHint("Tap to view and edit your profile settings")
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Welcome back!")
                            .font(AppTheme.Typography.title2)
                            .foregroundStyle(.primary)
                        
                        Text("Discover your skincare routine")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.screenEdge)
                .padding(.top, AppTheme.Spacing.md)
                
                // UV Index Component
                UVIndexView(theme: theme, uvService: uvService)
                    .padding(.horizontal, AppTheme.Spacing.screenEdge)
                
                // Time-based Routine Section
                timeBasedRoutineSection
                    .padding(.horizontal, AppTheme.Spacing.screenEdge)

                if !vm.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        HStack {
                            Label("Recommended for you", systemImage: "sparkles")
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenEdge)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppTheme.Spacing.md) {
                                ForEach(vm.recommendations) { product in
                                    NavigationLink(value: product) {
                                        VStack(spacing: AppTheme.Spacing.md) {
                                            // Product image - handle both remote URLs and local assets
                                            Group {
                                                if let imageURL = product.imageURL, !imageURL.isEmpty {
                                                    AsyncImage(url: URL(string: imageURL)) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 140, height: 140)
                                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                                    } placeholder: {
                                                        ProgressView()
                                                            .frame(width: 140, height: 140)
                                                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                                    }
                                                } else if !product.assetName.isEmpty {
                                                    Image(product.assetName)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 140, height: 140)
                                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                                } else {
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 140, height: 140)
                                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                                Text(product.name)
                                                    .font(AppTheme.Typography.headline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(product.brand)
                                                    .font(AppTheme.Typography.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .frame(width: 140)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(product.brand) \(product.name)")
                                    .accessibilityHint("Tap to view product details")
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.screenEdge)
                        }
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .refreshable { vm.load() }
        .onAppear { vm.load() }
        .sheet(isPresented: $showingProfile) {
            ProfileView(theme: theme)
                .environmentObject(profileVM)
                .environmentObject(notificationVM)
        }
    }
}

// MARK: - Scan (Legacy - Replaced by ScannerPage)
// Note: ScanScreen has been replaced by ScannerPage for better barcode scanning experience

// MARK: - Shared UI (Row + Detail + Helpers)

struct ProductRow: View {
    let product: Product
    let theme: AppTheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Product image - handle both remote URLs and local assets
            Group {
                if let imageURL = product.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                    }
                } else if !product.assetName.isEmpty {
                    Image(product.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                        .foregroundColor(.gray)
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(product.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(product.brand)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if !product.ingredients.isEmpty {
                    IngredientCloud(ingredients: Array(product.ingredients.prefix(2)))
                        .tint(theme.primary)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                if let rating = product.rating {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                    }
                }
                
                // Category badge
                Text(product.category)
                    .font(AppTheme.Typography.caption)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(theme.primary.opacity(0.12))
                    .foregroundStyle(theme.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.primary.opacity(0.2), lineWidth: 0.5)
                    )
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.brand) \(product.name)")
        .accessibilityHint("Tap to view product details")
    }
}

struct ContentStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color(.quaternaryLabel))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let theme: AppTheme
    
    private let tabs = [
        TabItem(icon: "house.fill", title: "Home", index: 0),
        TabItem(icon: "shippingbox.fill", title: "Products", index: 1),
        TabItem(icon: "camera.viewfinder", title: "Scan", index: 2, isSpecial: true),
        TabItem(icon: "brain.head.profile", title: "SyncAI", index: 3),
        TabItem(icon: "calendar.badge.clock", title: "Routine", index: 4)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.index) { tab in
                Button(action: {
                    selectedTab = tab.index
                }) {
                    if tab.isSpecial {
                        // Special styling for Scan tab - larger but within HIG bounds
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(selectedTab == tab.index ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    } else {
                        // Regular styling for other tabs - standard HIG sizing
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(selectedTab == tab.index ? theme.primary : .secondary)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(selectedTab == tab.index ? theme.primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 49) // Standard tab bar height per Apple HIG
        .background(Color(.systemBackground))
    }
}

struct TabItem {
    let icon: String
    let title: String
    let index: Int
    let isSpecial: Bool
    
    init(icon: String, title: String, index: Int, isSpecial: Bool = false) {
        self.icon = icon
        self.title = title
        self.index = index
        self.isSpecial = isSpecial
    }
}


