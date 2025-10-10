// Views/RootAndScreens.swift
import SwiftUI

// MARK: - Root (5 tabs): Home, Scan, Routine, Products, Profile
struct RootView: View {
    @EnvironmentObject private var app: AppModel

    // Shared dependencies so every view model uses the same store/services
    private let store: FileDataStore
    private let notif: NotificationScheduler
    private let productRepository: ProductRepository
    private let faceAPI: FaceScanService
    private let uvService: UVIndexService

    @StateObject private var homeVM: HomeViewModel
    @StateObject private var scanVM: ScanViewModel
    @StateObject private var routineVM: RoutineViewModel
    @StateObject private var productsVM: ProductsViewModel
    @StateObject private var profileVM: ProfileViewModel

    init() {
        let ds = FileDataStore()
        ds.seedIfNeeded() // copy bundled JSON to Documents on first run

        // Create services as locals first (so the app don't read stored properties before init finishes)
        let notifSvc = LocalNotificationScheduler()
        let productRepo = OpenBeautyFactsRepository(store: ds)  // Use new repository
        let faceSvc = MockFaceScanService()
        let uvSvc = OpenUVService(apiKey: "openuv-2sy4amrmgcdf6jo-io")

        // Assign to stored properties
        self.store = ds
        self.notif = notifSvc
        self.productRepository = productRepo
        self.faceAPI = faceSvc
        self.uvService = uvSvc

        // safe to build StateObjects using the local services
        _homeVM = StateObject(wrappedValue: HomeViewModel(store: ds))
        _scanVM = StateObject(wrappedValue: ScanViewModel(productRepository: productRepo,
                                                          faceAPI: faceSvc,
                                                          store: ds))
        _routineVM = StateObject(wrappedValue: RoutineViewModel(store: ds,
                                                                scheduler: notifSvc))
        _productsVM = StateObject(wrappedValue: ProductsViewModel(store: ds, productRepository: productRepo))
        _profileVM = StateObject(wrappedValue: ProfileViewModel(store: ds))
    }

    private var theme: AppTheme { AppTheme(config: app.config) }

    var body: some View {
        TabView {
            // Home
            NavigationStack {
                HomeView(theme: theme, uvService: uvService)
                    .environmentObject(homeVM)
                    .environmentObject(profileVM)
                    .environmentObject(productsVM)
                .navigationDestination(for: Product.self) { p in
                    ProductDetailView(product: p, theme: theme, store: store, productRepository: productRepository)
                        .environmentObject(productsVM)
                }
            }
            .environmentObject(routineVM)
            .tabItem { 
                Label("Home", systemImage: "house.fill")
            }

            // Scan
            ScannerPage(theme: theme, store: store, productRepository: productRepository)
                .environmentObject(scanVM)
                .environmentObject(productsVM)
                .environmentObject(routineVM)
                .tabItem { 
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            // Products
            NavigationStack {
                ProductsScreen(theme: theme)
                    .environmentObject(productsVM)
                    .navigationTitle("Products")
                .navigationDestination(for: Product.self) { p in
                    ProductDetailView(product: p, theme: theme, store: store, productRepository: productRepository)
                        .environmentObject(productsVM)
                }
            }
            .environmentObject(routineVM)
            .tabItem { 
                Label("Products", systemImage: "shippingbox.fill")
            }

            // Routine — use the SAME RoutineViewModel as Products/ProductDetailView
            NavigationStack {
                MyRoutineScreen(theme: theme)
                    .environmentObject(routineVM)  // <— key change (was TimelineViewModel)
                    .navigationTitle("Routine")
            }
            .tabItem { 
                Label("Routine", systemImage: "calendar.badge.clock")
            }

        }
        .tint(theme.primary)
        .onAppear {
            // initial loads
            homeVM.load()
            productsVM.load()
            routineVM.load()
        }
    }
}

// MARK: - Home (latest face scan + recommendations)
struct HomeView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var profileVM: ProfileViewModel
    let theme: AppTheme
    let uvService: UVIndexService
    @State private var showingProfile = false

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
                
                if let scan = vm.latestScan {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Label("Latest Face Scan", systemImage: "face.smiling")
                            .font(AppTheme.Typography.title3)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            if !scan.concerns.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("Detected Concerns")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: AppTheme.Spacing.sm) {
                                            ForEach(scan.concerns) { concern in
                                                Text(concern.title)
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
                                        .padding(.horizontal, AppTheme.Spacing.xs)
                                    }
                                }
                            }
                            
                            if let notes = scan.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("Notes")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    
                                    Text(notes)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(nil)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                        .shadow(color: theme.cardShadow, radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenEdge)
                } else {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        ContentStateView(
                            icon: "face.smiling",
                            title: "No face scans yet",
                            message: "Go to Scan → Face to analyze your skin and get personalized recommendations."
                        )
                        .padding(.horizontal, AppTheme.Spacing.screenEdge)
                        
                        Button(action: {}) {
                            Label("Take Face Scan", systemImage: "camera.viewfinder")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .background(theme.primary, in: RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Take Face Scan")
                        .accessibilityHint("Opens the camera to analyze your skin")
                    }
                }

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
                                                } else {
                                                    Image(product.assetName)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 140, height: 140)
                                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
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
                } else {
                    Image(product.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
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
