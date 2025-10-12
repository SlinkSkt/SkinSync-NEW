# ``SkinSync``

A comprehensive iOS skincare tracking and routine management app with AI-powered recommendations.

## Overview

SkinSync helps users manage their skincare routines, track products, scan barcodes and ingredients, monitor UV index for sun protection, and get personalized AI recommendations powered by OpenAI.

### Key Features

- **Smart Product Management**: Search and track skincare products with Open Beauty Facts integration
- **Barcode Scanning**: Scan product barcodes to instantly fetch product information
- **Routine Builder**: Create customizable morning and evening skincare routines with drag-and-drop
- **UV Index Monitoring**: Real-time UV index tracking with sun protection recommendations
- **AI Recommendations**: Get personalized skincare advice from SyncAI powered by OpenAI
- **Cloud Sync**: Firebase integration for cross-device synchronization
- **Favorites & Tracking**: Mark favorite products and track routine completion

## Topics


### Core Models

Data models representing the core domain of the app.

- ``Profile``
- ``Product``
- ``Ingredient``
- ``Routine``
- ``RoutineSlot``
- ``DayLog``
- ``NotificationPrefs``

### Enumerations

Type-safe enumerations for skin types, concerns, and goals.

- ``SkinType``
- ``SkinGoal``
- ``Concern``

### Authentication

User authentication and account management.

- ``AuthService``
- ``AuthServicing``
- ``AppUser``
- ``AuthViewModel``

### Product Management

Services and view models for managing skincare products.

- ``ProductRepository``
- ``ProductsViewModel``
- ``ProductDetailViewModel``
- ``FavoritesService``
- ``ScanViewModel``

### Routine Management

Building and tracking skincare routines.

- ``RoutineService``
- ``RoutineServicing``
- ``RoutineViewModel``
- ``NotificationScheduler``
- ``LocalNotificationScheduler``

### UV Index & Weather

Real-time UV index monitoring and sun protection.

- ``UVIndexService``
- ``OpenUVService``
- ``MockUVIndexService``
- ``UVIndexViewModel``
- ``UVIndexResult``
- ``UVIndexError``

### AI Integration

OpenAI-powered skincare recommendations.

- ``OpenAIService``
- ``SyncAIViewModel``

### Profile Management

User profile and preferences.

- ``ProfileService``
- ``ProfileViewModel``
- ``SettingsViewModel``

### Data Persistence

Local and cloud data storage.

- ``DataStore``
- ``SwiftDataService``

### Views

Main user interface screens.

- ``LoginView``
- ``ProductsScreen``
- ``ProductDetailView``
- ``FavoritesScreen``
- ``RoutineView``
- ``MyRoutineScreen``
- ``ProfileView``
- ``ProfileEditorViews``
- ``ScannerPage``
- ``SyncAIView``
- ``UVIndexView``
- ``RemindersSettingsView``

### Utilities

Helper components and utilities.

- ``Camera``
- ``ImageLoader``
- ``AssetOrRemoteImage``
- ``IngredientCloudLayout``

### Widgets

Home screen and lock screen widgets.

- ``UVIndexWidget``

### App Core

Core app configuration and theme.

- ``SkinSyncApp``
- ``AppModel``
- ``FirebaseManager``
- ``Theme``

## Architecture

SkinSync follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Domain objects representing data (Profile, Product, Routine)
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and state management (`@Published` properties)
- **Services**: Reusable services for API calls, data persistence, and external integrations

### Data Flow

1. **Views** observe **ViewModels** using `@ObservedObject` or `@StateObject`
2. **ViewModels** call **Services** to fetch or modify data
3. **Services** interact with external APIs, Firebase, or local storage
4. Data updates trigger view re-renders through `@Published` properties

## Integration & APIs

### Firebase
- **Authentication**: Google Sign-In integration
- **Firestore**: Cloud data synchronization for profiles, routines, and favorites

### Open Beauty Facts
- Product database with barcode lookup
- Ingredient information and product details

### OpenUV API
- Real-time UV index data
- Sun position and safe exposure time calculations

### OpenAI
- GPT-powered skincare recommendations
- Personalized advice based on user profile and products

## Testing

Unit tests cover core functionality:

- Model encoding/decoding and conversions
- Business logic in view models
- Service error handling
- Data persistence operations

Run tests with `Cmd + U` in Xcode.

## See Also

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Open Beauty Facts API](https://world.openbeautyfacts.org/data)
