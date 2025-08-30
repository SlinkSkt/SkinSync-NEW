// Views/RootAndScreens.swift
import SwiftUI

// MARK: - Root (5 tabs): Home, Scan, Routine, Products, Profile
struct RootView: View {
    @EnvironmentObject private var app: AppModel

    @StateObject private var homeVM = HomeViewModel(store: FileDataStore())
    @StateObject private var scanVM = ScanViewModel(productAPI: LocalProductAPI(),
                                                    faceAPI: MockFaceScanService(),
                                                    store: FileDataStore())
    @StateObject private var routineVM = RoutineViewModel(store: FileDataStore(),
                                                          scheduler: LocalNotificationScheduler())
    @StateObject private var productsVM = ProductsViewModel(store: FileDataStore())
    @StateObject private var profileVM = ProfileViewModel(store: FileDataStore())

    var body: some View {
        let theme = AppTheme(config: app.config)
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
            VStack(alignment: .leading, spacing: 16) {
                if let scan = vm.latestScan {
                    GroupBox("Latest Face Scan") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(scan.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                            HStack {
                                ForEach(scan.concerns) { c in
                                    Text(c.title).font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(theme.primary.opacity(0.15))
                                        .foregroundStyle(theme.primary)
                                        .clipShape(Capsule())
                                }
                            }
                            if let n = scan.notes, !n.isEmpty {
                                Text(n).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    ContentStateView(icon: "face.smiling",
                                     title: "No face scans yet",
                                     message: "Go to Scan → Face to analyze your skin.")
                }

                if !vm.recommendations.isEmpty {
                    Text("Recommended for you").font(.title2.bold())
                    ForEach(vm.recommendations) { p in
                        NavigationLink(value: p) { ProductRow(product: p, theme: theme) }
                    }
                }
            }
            .padding()
        }
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
        HStack(spacing: 12) {
            Image(product.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.headline)
                Text(product.brand).font(.subheadline).foregroundStyle(.secondary)
                IngredientCloud(ingredients: product.ingredients).tint(theme.primary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ContentStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40))
            Text(title).font(.title3.weight(.semibold))
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct AsyncRemoteImage: View {
    let url: URL?; var placeholderSystemName: String = "photo"
    var body: some View {
        ZStack {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure: Image(systemName: placeholderSystemName).resizable().scaledToFit().padding(12).foregroundStyle(.secondary)
                    @unknown default: EmptyView()
                    }
                }
            } else {
                Image(systemName: placeholderSystemName).resizable().scaledToFit().padding(12).foregroundStyle(.secondary)
            }
        }
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
