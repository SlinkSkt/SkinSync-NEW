// Views/RootAndScreens.swift
import SwiftUI

// MARK: - Root (5 tabs): Home, Scan, Routine, Products, Profile
struct RootView: View {
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

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

    // Optimized theme creation - only recreates when config or colorScheme changes
    private var theme: AppTheme { 
        AppTheme(config: app.config, colorScheme: colorScheme) 
    }

    @State private var selectedTab = 0
    @State private var showTabBar = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            VStack(spacing: 0) {
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
                    RoutineView(theme: theme)
                        .environmentObject(productsVM)
                        .environmentObject(routineVM)
                    
                default:
                    EmptyView()
                }
            }
            }
            
            // Custom Tab Bar (in ZStack, overlaying content)
            if showTabBar {
                CustomTabBar(selectedTab: $selectedTab, theme: theme)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(theme.primary)
        .fullScreenCover(
            isPresented: Binding(get: { auth.user == nil }, set: { _ in })
        ) {
            LoginView(
                isLoading: auth.isLoading,
                errorMessage: auth.error,
                onSignIn: { auth.signInWithGoogle() }
            )
        }
        .onAppear {
            homeVM.load()
            productsVM.load()
            Task { await routineVM.load() }
        }


    }
}

// MARK: - Home (latest scan + recommendations)
struct HomeView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var notificationVM: NotificationViewModel
    @EnvironmentObject private var routineVM: RoutineViewModel
    @EnvironmentObject private var auth: AuthViewModel
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
        .background(
            ZStack {
                // Premium card background
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(theme.cardBackground)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        (isMorningTime ? theme.success : theme.info).opacity(0.08),
                        (isMorningTime ? theme.success : theme.info).opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (isMorningTime ? theme.success : theme.info).opacity(0.3),
                            (isMorningTime ? theme.success : theme.info).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 6)
        .shadow(color: (isMorningTime ? theme.success : theme.info).opacity(0.08), radius: 20, x: 0, y: 10)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.section) {
                // Welcome header with profile button
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Button {
                        showingProfile = true
                    } label: {
                        ZStack {
                            // Gradient background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryLight, theme.primary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: profileVM.profile.profileIcon)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 56, height: 56)
                        .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .background(theme.background)
        .refreshable { vm.load() }
        .onAppear { vm.load() }
        .sheet(isPresented: $showingProfile) {
            ProfileView(theme: theme)
                .environmentObject(profileVM)
                .environmentObject(notificationVM)
                .environmentObject(auth)
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                    .fill(theme.cardBackground)
                
                // Subtle gradient
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                .strokeBorder(theme.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: theme.subtleShadow, radius: 8, x: 0, y: 4)
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
    @Environment(\.colorScheme) private var colorScheme
    
    private let tabs = [
        TabItem(icon: "sparkles", selectedIcon: "sparkles", title: "Home", index: 0),
        TabItem(icon: "cube.box", selectedIcon: "cube.box.fill", title: "Products", index: 1),
        TabItem(icon: "qrcode.viewfinder", selectedIcon: "qrcode.viewfinder", title: "Scan", index: 2, isSpecial: true),
        TabItem(icon: "sparkle.magnifyingglass", selectedIcon: "sparkle.magnifyingglass", title: "SyncAI", index: 3),
        TabItem(icon: "star.circle", selectedIcon: "star.circle.fill", title: "Routine", index: 4)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab bar background with blur
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.index) { tab in
                        if !tab.isSpecial {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab.index
                                }
                            }) {
                                TabBarButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab.index,
                                    theme: theme
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Spacer for floating scan button
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 70)
                .background(
                    GeometryReader { geometry in
                        ZStack {
                            // Solid background (no transparency to avoid white blocks)
                            (colorScheme == .dark ? Color.black : Color.white)
                                .frame(height: geometry.size.height + geometry.safeAreaInsets.bottom)
                            
                            // Subtle blur overlay
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.5)
                                .frame(height: geometry.size.height + geometry.safeAreaInsets.bottom)
                        }
                        .edgesIgnoringSafeArea(.bottom)
                    }
                )
                .overlay(
                    // Top border gradient
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.2),
                            theme.primary.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1),
                    alignment: .top
                )
            }
            
            // Floating Scan Button (centered, less elevated)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    selectedTab = 2
                }
            }) {
                FloatingScanButton(
                    isSelected: selectedTab == 2,
                    theme: theme
                )
            }
            .buttonStyle(.plain)
            .offset(y: -15) // Float above tab bar (reduced from -20)
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Selection indicator background
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary.opacity(0.15))
                        .frame(width: 50, height: 32)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Icon with animated fill
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected 
                            ? LinearGradient(
                                colors: [theme.primary, theme.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.secondary, Color.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            // Label
            Text(tab.title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Floating Scan Button
struct FloatingScanButton: View {
    let isSelected: Bool
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Outer glow ring (smaller)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.primary.opacity(0.3),
                                theme.primary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 22,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 4)
                
                // Main button with gradient (smaller)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryLight, theme.primary, theme.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .blur(radius: 0.5)
                    )
                
                // Icon with animation (smaller)
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .rotationEffect(.degrees(isSelected ? 360 : 0))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Label with premium style (smaller)
            Text("Scan")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.primaryDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(y: -2)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
}

struct TabItem {
    let icon: String
    let selectedIcon: String
    let title: String
    let index: Int
    let isSpecial: Bool
    
    init(icon: String, selectedIcon: String? = nil, title: String, index: Int, isSpecial: Bool = false) {
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.title = title
        self.index = index
        self.isSpecial = isSpecial
    }
}


