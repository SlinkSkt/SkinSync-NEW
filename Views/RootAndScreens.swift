// Views/RootAndScreens.swift
import SwiftUI

// MARK: - Root (5 tabs): Home, Scan, Routine, Products, Profile
struct RootView: View {
    @EnvironmentObject private var app: AppModel

    // Shared dependencies so every view model uses the same store/services
    private let store: FileDataStore
    private let notif: NotificationScheduler
    private let productAPI: ProductAPI
    private let faceAPI: FaceScanService

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
        let productSvc = LocalProductAPI()
        let faceSvc = MockFaceScanService()

        // Assign to stored properties
        self.store = ds
        self.notif = notifSvc
        self.productAPI = productSvc
        self.faceAPI = faceSvc

        // safe to build StateObjects using the local services
        _homeVM = StateObject(wrappedValue: HomeViewModel(store: ds))
        _scanVM = StateObject(wrappedValue: ScanViewModel(productAPI: productSvc,
                                                          faceAPI: faceSvc,
                                                          store: ds))
        _routineVM = StateObject(wrappedValue: RoutineViewModel(store: ds,
                                                                scheduler: notifSvc))
        _productsVM = StateObject(wrappedValue: ProductsViewModel(store: ds))
        _profileVM = StateObject(wrappedValue: ProfileViewModel(store: ds))
    }

    private var theme: AppTheme { AppTheme(config: app.config) }

    var body: some View {
        TabView {
            // Home
            NavigationStack {
                HomeView(theme: theme)
                    .environmentObject(homeVM)
                    .navigationTitle("Home")
                    .navigationDestination(for: Product.self) { p in
                        ProductDetailView(product: p, theme: theme)
                    }
            }
            .environmentObject(routineVM)
            .tabItem { Label("Home", systemImage: "house") }

            // Scan
            NavigationStack {
                ScanScreen(theme: theme)
                    .environmentObject(scanVM)
                    .navigationTitle("Scan")
                    .navigationDestination(for: Product.self) { p in
                        ProductDetailView(product: p, theme: theme)
                    }
            }
            .environmentObject(routineVM)
            .tabItem { Label("Scan", systemImage: "viewfinder") }

            // Routine — use the SAME RoutineViewModel as Products/ProductDetailView
            NavigationStack {
                MyRoutineScreen(theme: theme)
                    .environmentObject(routineVM)  // <— key change (was TimelineViewModel)
                    .navigationTitle("Routine")
            }
            .tabItem { Label("Routine", systemImage: "calendar") }

            // Products
            NavigationStack {
                ProductsScreen(theme: theme)
                    .environmentObject(productsVM)
                    .navigationTitle("Products")
                    .navigationDestination(for: Product.self) { p in
                        ProductDetailView(product: p, theme: theme)
                    }
            }
            .environmentObject(routineVM)
            .tabItem { Label("Products", systemImage: "books.vertical") }

            // Profile
            NavigationStack {
                ProfileScreen(theme: theme)
                    .environmentObject(profileVM)
                    .navigationTitle("Profile")
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
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
    let theme: AppTheme

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                // Welcome header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Welcome back!")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(.primary)
                    
                    Text("Discover your skincare routine")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                if let scan = vm.latestScan {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Latest Face Scan", systemImage: "face.smiling")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            if !scan.concerns.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        ForEach(scan.concerns) { concern in
                                            Text(concern.title)
                                                .font(AppTheme.Typography.caption)
                                                .padding(.horizontal, AppTheme.Spacing.md)
                                                .padding(.vertical, AppTheme.Spacing.sm)
                                                .background(theme.primary.opacity(0.15))
                                                .foregroundStyle(theme.primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 1) // Allows shadow to show
                                }
                            }
                            
                            if let notes = scan.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, AppTheme.Spacing.xs)
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                        .shadow(color: theme.cardShadow, radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                } else {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        ContentStateView(
                            icon: "face.smiling",
                            title: "No face scans yet",
                            message: "Go to Scan → Face to analyze your skin and get personalized recommendations."
                        )
                        .padding(.horizontal, AppTheme.Spacing.md)
                        
                        Button(action: {}) {
                            Label("Take Face Scan", systemImage: "camera.viewfinder")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .background(theme.primary, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !vm.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Label("Recommended for you", systemImage: "sparkles")
                                .font(AppTheme.Typography.title)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppTheme.Spacing.md) {
                                ForEach(vm.recommendations) { product in
                                    NavigationLink(value: product) {
                                        VStack(spacing: AppTheme.Spacing.md) {
                                            Image(product.assetName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 140, height: 140)
                                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))
                                            
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                                Text(product.name)
                                                    .font(AppTheme.Typography.headline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(product.brand)
                                                    .font(AppTheme.Typography.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .frame(width: 140)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 1)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                        }
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .refreshable { vm.load() }
        .onAppear { vm.load() }
    }
}

// MARK: - Scan (Barcode | Face)
struct ScanScreen: View {
    enum Mode: String, CaseIterable, Identifiable { case barcode = "Barcode", face = "Face"; var id: String { rawValue } }
    @EnvironmentObject private var vm: ScanViewModel
    @State private var mode: Mode = .barcode
    @StateObject private var cam = CameraSessionController()
    let theme: AppTheme

    var body: some View {
        VStack {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if mode == .barcode {
                BarcodeScannerView { code in vm.onBarcode(code) }
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()

                if let p = vm.scannedProduct {
                    ProductRow(product: p, theme: theme).padding(.horizontal)
                    NavigationLink("View details", value: p).padding(.horizontal)
                } else {
                    ContentStateView(icon: "barcode.viewfinder",
                                     title: "Scan a product",
                                     message: "Point the camera at a barcode.")
                    .padding()
                }
            } else {
                FaceCameraView(controller: cam)
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()

                HStack {
                    Button { cam.capture() } label: {
                        Label("Capture", systemImage: "camera.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        if let img = cam.lastImage { vm.analyzeFace(image: img) }
                    } label: { Label("Analyze", systemImage: "wand.and.stars") }
                    .buttonStyle(.bordered)
                    .disabled(cam.lastImage == nil || vm.analyzingFace)
                }
                .padding(.bottom)

                if vm.analyzingFace {
                    ProgressView("Analyzing…")
                } else if let r = vm.lastFaceScan {
                    GroupBox("Detected concerns") {
                        HStack {
                            ForEach(r.concerns) { c in
                                Text(c.title).font(.caption)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(theme.primary.opacity(0.15))
                                    .foregroundStyle(theme.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ContentStateView(icon: "face.smiling",
                                     title: "Capture a selfie",
                                     message: "Then tap Analyze to detect concerns.")
                    .padding()
                }
            }
            Spacer()
        }
    }
}

// MARK: - Profile
struct ProfileScreen: View {
    @EnvironmentObject private var vm: ProfileViewModel
    let theme: AppTheme
    @State private var newAllergy: String = ""

    var body: some View {
        Form {
            Section("User") {
                TextField("Nickname", text: Binding(
                    get: { vm.profile.nickname }, set: { vm.profile.nickname = $0; vm.save() }))
                TextField("Year of birth range (e.g., 2001-2005)", text: Binding(
                    get: { vm.profile.yearOfBirthRange }, set: { vm.profile.yearOfBirthRange = $0; vm.save() }))
            }
            Section("Skin") {
                Picker("Skin type", selection: Binding(
                    get: { vm.profile.skinType }, set: { vm.profile.skinType = $0; vm.save() })) {
                    ForEach(SkinType.allCases) { t in Text(t.rawValue.capitalized).tag(t) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Allergies")
                    HStack {
                        TextField("Add allergy", text: $newAllergy)
                        Button("Add") {
                            let a = newAllergy.trimmingCharacters(in: .whitespaces)
                            guard !a.isEmpty else { return }
                            vm.profile.allergies.append(a); newAllergy = ""; vm.save()
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(vm.profile.allergies.enumerated()), id: \.offset) { idx, a in
                                HStack(spacing: 6) {
                                    Text(a).font(.caption)
                                    Button {
                                        vm.profile.allergies.remove(at: idx); vm.save()
                                    } label: { Image(systemName: "xmark.circle.fill") }
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(theme.primary.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                Section("Goals") {
                    ForEach(SkinGoal.allCases) { g in
                        Toggle(g.rawValue, isOn: Binding(
                            get: { vm.profile.goals.contains(g) },
                            set: { isOn in
                                if isOn { vm.profile.goals.append(g) }
                                else { vm.profile.goals.removeAll { $0 == g } }
                                vm.save()
                            }
                        ))
                    }
                }
            }
        }
    }
}

// MARK: - Shared UI (Row + Detail + Helpers)

struct ProductRow: View {
    let product: Product
    let theme: AppTheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(product.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(product.name)
                    .font(AppTheme.Typography.headline)
                    .lineLimit(2)
                
                Text(product.brand)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
                
                if !product.ingredients.isEmpty {
                    IngredientCloud(ingredients: Array(product.ingredients.prefix(2)))
                        .tint(theme.primary)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                if let rating = product.rating {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                
                // Category badge
                Text(product.category)
                    .font(AppTheme.Typography.caption)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(theme.primary.opacity(0.1))
                    .foregroundStyle(theme.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

struct ContentStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color(.quaternaryLabel))
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
