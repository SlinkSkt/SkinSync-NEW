Group members:  
Zhen Xiao s3894630 
Adam Chahrouk s3946215 

 
Git repository URL:  
https://github.com/rmit-iPSE-s2-2025/a2-s3894630-3946215.git

Miro Board URL:
https://miro.com/app/board/uXjVJKyFvys=/?share_link_id=160335133053
  
References 
Think Dirty (2025) Think Dirty, Shop Clean. Apple App Store. Available at: https://apps.apple.com/us/app/think-dirty-shop-clean/id687176839 (Accessed: 24 August 2025). 

Yuka (2025) Yuka: Food and Cosmetic Scanner. Available at: https://yuka.io/en/ (Accessed: 24 August 2025). 

OnSkin (2025) OnSkin, AI Skin Analysis App. Available at: https://onskin.com/ (Accessed: 24 August 2025). 

MDacne (2025) MDacne, Personalized Acne Treatment. Available at: https://www.mdacne.com/?srsltid=AfmBOooCxiBT2xQyTT5alx1hCvI-P4LqbHhgijMAErmJr1NTdAQX7u_O  (Accessed: 24 August 2025). 

Apple Human Interface Guidelines. Apple Developer. Available at: https://developer.apple.com/design/human-interface-guidelines (Accessed: 25 August 2025).  

Open Beauty Facts API. Available at: https://world.openbeautyfacts.org/data (Accessed: 25 August 2025). 



# SkinSync

A comprehensive iOS skincare tracking and routine management app with AI-powered recommendations, barcode scanning, and real-time UV index monitoring.


![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green.svg)
![Firebase](https://img.shields.io/badge/Firebase-10.0-yellow.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)



---

## About

**SkinSync** is an intelligent skincare companion that helps users build personalized skincare routines, track products, scan ingredients, and receive AI-powered recommendations. With real-time UV index monitoring and cloud synchronization, SkinSync makes skincare management effortless.

### Key Features

- **Smart Product Search** - Search and discover skincare products via Open Beauty Facts API
- **Barcode Scanner** - Instantly fetch product information by scanning barcodes
- **Routine Builder** - Create customizable morning and evening routines with drag-and-drop
- **UV Index Tracking** - Real-time UV monitoring with sun protection recommendations
- **SyncAI Assistant** - OpenAI-powered personalized skincare advice
- **Favorites & Tracking** - Mark favorites and track daily routine completion
- **Cloud Sync** - Firebase integration for cross-device synchronization
- **Smart Reminders** - Local notifications for routine reminders
- **Home Screen Widget** - Quick UV index widget for iOS home screen

---

## Tech Stack & Tools

### Frontend
- **SwiftUI** - Modern declarative UI framework
- **MVVM Architecture** - Clean separation of concerns
- **Combine Framework** - Reactive programming for data flow
- **WidgetKit** - Home screen widgets

### Backend & Services
- **Firebase Authentication** - Google Sign-In integration
- **Firebase Firestore** - Real-time cloud database for user data
- **SwiftData** - Local data persistence (iOS 17+)
- **UserNotifications** - Local push notifications

### APIs & Integrations
- **OpenAI API** (GPT-4) - AI-powered skincare recommendations
- **Open Beauty Facts API** - Product database with 2M+ beauty products
- **OpenUV API** - Real-time UV index and sun safety data
- **Core Location** - Location services for UV tracking

### Camera & Scanning
- **AVFoundation** - Camera access for barcode scanning
- **Vision Framework** - Barcode detection and recognition

### Development Tools
- **Xcode 15+** - Primary IDE
- **Swift Package Manager** - Dependency management
- **XCTest** - Unit testing framework
- **DocC** - Documentation generation

### Dependencies

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
]
```

---

## Architecture

SkinSync follows the **MVVM (Model-View-ViewModel)** pattern:
┌─────────────────────────────────────────────────┐
│                    Views                        │
│  (SwiftUI, User Interface Components)          │
└──────────────────┬──────────────────────────────┘
                   │ @Published / @ObservedObject
┌──────────────────▼──────────────────────────────┐
│                ViewModels                       │
│  (Business Logic, State Management)             │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│                 Services                        │
│  (APIs, Firebase, DataStore, Camera)            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│                  Models                         │
│  (Domain Objects: Product, Profile, Routine)    │
└─────────────

SkinSync/
├── Core/                    # App initialization & configuration
│   ├── SkinSyncApp.swift   # Main app entry point
│   ├── AppModel.swift       # Global app state
│   ├── FirebaseManager.swift
│   └── Theme.swift          # App theme & colors
├── Models/                  # Domain models
│   ├── Domain.swift         # Core data models
│   └── SwiftDataModels.swift
├── Views/                   # SwiftUI views
│   ├── LoginView.swift
│   ├── ProductsScreen.swift
│   ├── RoutineView.swift
│   ├── ScannerPage.swift
│   ├── SyncAIView.swift
│   └── UVIndexView.swift
├── ViewModels/              # Business logic
│   ├── ProductsViewModel.swift
│   ├── RoutineViewModel.swift
│   ├── ScanViewModel.swift
│   └── UVIndexViewModel.swift
├── Services/                # External integrations
│   ├── AuthService.swift
│   ├── ProductRepository.swift
│   ├── UVIndexService.swift
│   ├── OpenAIService.swift
│   ├── DataStore.swift
│   └── Camera.swift
├── Utils/                   # Utilities & helpers
├── Resources/               # Assets & data files
├── SkinSyncWidgets/         # Widget extension
└── SkinSyncTests/           # Unit tests `Cmd + R`

---

## API Keys Required

| Service | Purpose | Get Key |
|---------|---------|---------|
| **OpenAI** | AI skincare recommendations | [OpenAI Platform](https://platform.openai.com/) |
| **OpenUV** | Real-time UV index data | [OpenUV API](https://www.openuv.io/) |
| **Firebase** | Authentication & Cloud sync | [Firebase Console](https://console.firebase.google.com/) |
| **Open Beauty Facts** | Product database (public API) | No key required |

---

## Testing

Run unit tests with:

```bash
# In Xcode
Cmd + U

# Or via command line
xcodebuild test -scheme SkinSync -destination 'platform=iOS Simulator,name=iPhone 15'
```

Test coverage includes:
- Model encoding/decoding
- ViewModel business logic
- Service error handling
- Data persistence

---

## Features in Detail

### Product Management
- Search 2M+ beauty products from Open Beauty Facts
- Barcode scanning with AVFoundation
- Detailed ingredient information
- Favorite products for quick access
- Product ratings and reviews

### Routine Builder
- Drag-and-drop interface
- Morning and evening routines
- Step-by-step tracking
- Completion history
- Custom product order

### UV Index Monitor
- Real-time UV data from OpenUV
- Location-based tracking
- Safe exposure time recommendations
- Sun protection tips
- Home screen widget

### SyncAI Assistant
- OpenAI GPT-4 powered
- Personalized skincare advice
- Product recommendations
- Routine suggestions
- Ingredient analysis

---

## Authors

- **Zhen Xiao** - *Initial work* - Student ID: 3894630
- **Adam** - Student ID: 3946215

**Course**: COSC2659 - iOS Development  
**Institution**: RMIT University  
**Year**: 2025

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Firebase** - Authentication and cloud storage
- **OpenAI** - AI-powered recommendations
- **Open Beauty Facts** - Product database
- **OpenUV** - UV index data
- **RMIT University** - iOS Development course materials
- **Apple** - SwiftUI and iOS SDK

---
