import SwiftUI
import VisionKit
import AVFoundation

struct ScannerPage: View {
    @StateObject private var viewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var productsVM: ProductsViewModel
    @State private var showingProductDetail = false
    @State private var navigateToProducts = false
    
    let theme: AppTheme
    let store: DataStore
    let productRepository: ProductRepository?
    
    init(theme: AppTheme, store: DataStore, productRepository: ProductRepository?) {
        self.theme = theme
        self.store = store
        self.productRepository = productRepository
        self._viewModel = StateObject(wrappedValue: ScanViewModel(
            productRepository: productRepository,
            faceAPI: MockFaceAPI(),
            store: store
        ))
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                premiumHeaderView
                
                // Scanner Content with enhanced design
                enhancedScannerContentView
                
                // Premium Status Bar
                premiumStatusBarView
            }
            
            // Enhanced Loading Overlay
            if viewModel.isLoading {
                premiumLoadingOverlay
            }
            
            // Enhanced Product Not Found Overlay
            if viewModel.showProductNotFound {
                premiumProductNotFoundOverlay
            }
        }
        .onAppear {
            if viewModel.cameraPermissionStatus == .authorized {
                viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: viewModel.scannedProduct) { oldValue, newValue in
            if newValue != nil {
                showingProductDetail = true
            }
        }
        .sheet(isPresented: $showingProductDetail, onDismiss: {
            // Reset scanner when sheet is dismissed
            print("🔍 ScannerPage: Sheet dismissed, resetting scanner")
            viewModel.reset()
            
            // Small delay to ensure reset completes before starting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🔍 ScannerPage: Starting scanner after reset")
                viewModel.startScanning()
            }
        }) {
            if let product = viewModel.scannedProduct {
                NavigationView {
                    ProductDetailView(product: product, theme: theme, store: store, productRepository: productRepository)
                        .environmentObject(productsVM)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingProductDetail = false
                                }
                                .foregroundStyle(.white)
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $navigateToProducts) {
            NavigationStack {
                ProductsScreen(theme: theme)
                    .environmentObject(productsVM)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                navigateToProducts = false
                                // Reset scanner when returning from products
                                viewModel.reset()
                                viewModel.startScanning()
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .onAppear {
                        // Ensure products are loaded when presented from scanner
                        print("🔍 ScannerPage: ProductsScreen appeared, ensuring products are loaded")
                        Task {
                            await productsVM.loadAsync()
                        }
                    }
                    .navigationDestination(for: Product.self) { product in
                        ProductDetailView(product: product, theme: theme, store: store, productRepository: productRepository)
                            .environmentObject(productsVM)
                    }
            }
        }
    }
    
    // MARK: - Premium Header View
    private var premiumHeaderView: some View {
        VStack(spacing: 0) {
            // Centered title without close button
            VStack(spacing: 4) {
                Text("Scan Product")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Point camera at barcode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.lg)
            
            // Subtle separator line
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
        }
    }
    
    // MARK: - Enhanced Scanner Content View
    private var enhancedScannerContentView: some View {
        ZStack {
            Group {
                switch viewModel.cameraPermissionStatus {
                case .notDetermined:
                    premiumPermissionRequestView
                case .denied, .restricted:
                    premiumPermissionDeniedView
                case .authorized:
                    if viewModel.isDataScannerAvailable {
                        premiumDataScannerView
                    } else {
                        premiumFallbackScannerView
                    }
                @unknown default:
                    premiumPermissionDeniedView
                }
            }
            
            // Premium scanning overlay
            if viewModel.isScanning && viewModel.cameraPermissionStatus == .authorized {
                premiumScanningOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Premium Scanning Overlay
    private var premiumScanningOverlay: some View {
        ZStack {
            // Simple, clean scanning frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white, lineWidth: 2)
                .frame(width: 260, height: 160)
                .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
            
            // Corner indicators - simplified
            VStack {
                HStack {
                    // Top-left corner
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 25, height: 4)
                        Rectangle()
                            .fill(.white)
                            .frame(width: 4, height: 25)
                    }
                    
                    Spacer()
                    
                    // Top-right corner
                    VStack(alignment: .trailing, spacing: 0) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 25, height: 4)
                        Rectangle()
                            .fill(.white)
                            .frame(width: 4, height: 25)
                    }
                }
                
                Spacer()
                
                HStack {
                    // Bottom-left corner
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 4, height: 25)
                        Rectangle()
                            .fill(.white)
                            .frame(width: 25, height: 4)
                    }
                    
                    Spacer()
                    
                    // Bottom-right corner
                    VStack(alignment: .trailing, spacing: 0) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 4, height: 25)
                        Rectangle()
                            .fill(.white)
                            .frame(width: 25, height: 4)
                    }
                }
            }
            .frame(width: 260, height: 160)
            
            // Scanning instruction - positioned below frame
            VStack {
                Spacer()
                
                Text("Align barcode within frame")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Premium Permission Request View
    private var premiumPermissionRequestView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Animated camera icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
            }
            .scaleEffect(viewModel.isScanning ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isScanning)
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Camera Access Required")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("SkinSync needs camera access to scan product barcodes and provide you with detailed product information.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    // Animation trigger
                }
                Task {
                    await viewModel.requestCameraPermission()
                }
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Allow Camera Access")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Premium Permission Denied View
    private var premiumPermissionDeniedView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Animated warning icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "camera.badge.exclamationmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Camera Access Denied")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Please enable camera access in Settings to scan product barcodes.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Open Settings")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Reset scanner and let user manually go to Products tab
                        viewModel.reset()
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Use Products Tab")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Premium DataScanner View
    private var premiumDataScannerView: some View {
        DataScannerViewControllerRepresentable(
            isScanning: $viewModel.isScanning,
            onBarcodeDetected: viewModel.onBarcodeDetected
        )
        .ignoresSafeArea()
        .overlay(
            // Subtle vignette effect
            RadialGradient(
                colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.1),
                    .black.opacity(0.3)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
        )
    }
    
    // MARK: - Premium Fallback Scanner View
    private var premiumFallbackScannerView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Animated barcode icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Scanner Not Available")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Advanced barcode scanning is not available on this device. Please use the search feature to find products.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Reset scanner and let user manually go to Products tab
                    viewModel.reset()
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Use Products Tab")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Premium Status Bar View
    private var premiumStatusBarView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Detected Barcode with premium styling
            if let detectedBarcode = viewModel.detectedBarcode {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Text("Detected: \(detectedBarcode)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Error Message with premium styling
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Bottom spacing
            Spacer()
                .frame(height: AppTheme.Spacing.lg)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
    
    // MARK: - Premium Loading Overlay
    private var premiumLoadingOverlay: some View {
        ZStack {
            // Premium blur background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                // Animated loading icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Looking up product...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Searching Open Beauty Facts database")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.reset()
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Premium Product Not Found Overlay
    private var premiumProductNotFoundOverlay: some View {
        ZStack {
            // Premium blur background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                // Animated question mark icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.orange)
                }
                
                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("Product Not Found")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    if let barcode = viewModel.detectedBarcode {
                        Text("No product found for barcode: \(barcode)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.reset()
                            viewModel.startScanning()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Scan Again")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                        .background(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Navigate to Products page
                            navigateToProducts = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Search Products")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .transition(.opacity)
    }
}

// MARK: - DataScanner ViewController Representable
struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    let onBarcodeDetected: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .accurate, // Use accurate for best quality
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        
        // Configure for better quality and performance
        scanner.overlayContainerView.backgroundColor = UIColor.clear
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning && !uiViewController.isScanning {
            print("🔍 DataScanner: Starting scanning with quality level: accurate")
            try? uiViewController.startScanning()
        } else if !isScanning && uiViewController.isScanning {
            print("🔍 DataScanner: Stopping scanning")
            uiViewController.stopScanning()
        }
        
        // Maintain quality settings
        uiViewController.overlayContainerView.backgroundColor = UIColor.clear
        
        // Note: DataScannerViewController doesn't support torch control
        // Torch functionality would need to be implemented separately if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeDetected: (String) -> Void
        private var detectedBarcodes: Set<String> = []
        
        init(onBarcodeDetected: @escaping (String) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
        }
        
        // Automatic detection when barcode is recognized
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue,
                       !detectedBarcodes.contains(payload) {
                        detectedBarcodes.insert(payload)
                        print("🔍 DataScanner: Auto-detected barcode: \(payload)")
                        onBarcodeDetected(payload)
                    }
                default:
                    break
                }
            }
        }
        
        // Manual tap detection (backup)
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    print("🔍 DataScanner: Tapped barcode: \(payload)")
                    onBarcodeDetected(payload)
                }
            default:
                break
            }
        }
        
        // Clean up detected barcodes when items are removed
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in removedItems {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue {
                        detectedBarcodes.remove(payload)
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Mock Face API
struct MockFaceAPI {
    // Placeholder for face analysis API
}

#Preview {
    ScannerPage(
        theme: AppTheme(config: .default),
        store: FileDataStore(),
        productRepository: nil
    )
    .environmentObject(ProductsViewModel(store: FileDataStore(), productRepository: nil))
}
