# MaidMatch App

MaidMatch is a Flutter-based mobile application that connects homeowners with trusted household help. The app streamlines the process of finding and hiring reliable maids while ensuring safety and convenience for both parties.

## Features

- **User Authentication**
  - Phone number-based OTP authentication
  - Role-based access (Admin, Maid, Homeowner)
  - Secure login and registration

- **Maid Features**
  - Professional profile creation
  - Document verification
  - Location-based services
  - Application tracking
  - Job acceptance and management

- **Homeowner Features**
  - Maid search and filtering
  - Booking management
  - Location-based maid discovery
  - Rating and review system

- **Admin Panel**
  - User management
  - Application verification
  - Document approval
  - System monitoring

## Technology Stack

- **Frontend**
  - Flutter SDK
  - Material Design
  - Google Maps Flutter
  - Provider for state management
  - Cached Network Image for efficient image loading

- **Backend & Services**
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Functions

- **Maps & Location**
  - Google Maps API
  - Geocoding
  - Geolocator
  - Map Launcher

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  provider: ^6.1.1
  google_maps_flutter: ^2.5.0
  geocoding: ^2.1.1
  geolocator: ^10.1.0
  image_picker: ^1.0.5
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.7
  map_launcher: ^2.5.0+1
```

## Getting Started

1. **Prerequisites**
   - Flutter SDK
   - Android Studio / VS Code
   - Firebase account
   - Google Maps API key

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/ClaireAgaba/maidmatch_app.git

   # Navigate to project directory
   cd maidmatch_app

   # Install dependencies
   flutter pub get

   # Run the app
   flutter run
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Add your Android/iOS app in Firebase console
   - Download and add google-services.json/GoogleService-Info.plist
   - Enable Phone Authentication in Firebase Console
   - Set up Cloud Firestore rules

## Project Structure

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── screens/         # UI screens
│   ├── admin/       # Admin screens
│   ├── auth/        # Authentication screens
│   ├── maid/        # Maid screens
│   └── homeowner/   # Homeowner screens
├── services/        # Business logic and services
├── utils/          # Utility functions
└── main.dart       # App entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Contact

Claire Agaba - [@ClaireAgaba](https://github.com/ClaireAgaba)

Project Link: [https://github.com/ClaireAgaba/maidmatch_app](https://github.com/ClaireAgaba/maidmatch_app)
