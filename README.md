# DueZy

DueZy is a premium, highly aesthetic bill and EMI reminder application built with Flutter and Firebase. It features a sleek glassmorphic dashboard, real-time Firestore synchronization, offline resilience, local notifications, and scope-based security with anonymous authentication.

## Features

- **Dashboard**: High-quality visual summaries of total due, paid, and pending bills.
- **Categorization**: Visual indicators and badges for EMI, Subscriptions, Bills, and Custom reminders.
- **Payment Windows**: Schedule notifications and mark bills as paid per billing cycle.
- **Notifications**: Local notifications to warn users before payment deadlines.
- **Dark Mode**: High-contrast dark theme and seamless light/dark mode transitions.
- **Resilience**: Anonymous Firebase Auth and local preferences caching.

## Tech Stack

- **Framework**: Flutter (Dart)
- **Database**: Cloud Firestore
- **Auth**: Firebase Anonymous Auth
- **State Management & Caching**: SharedPreferences
- **Notifications**: flutter_local_notifications

## Getting Started

1. Ensure the Flutter SDK is installed on your machine.
2. Run the command to install the required packages:
   ```bash
   flutter pub get
   ```
3. Launch the application on your device or emulator:
   ```bash
   flutter run
   ```

## Development and Testing

Verify code structure:
```bash
flutter analyze
```

Run unit tests:
```bash
flutter test
```
