samples, guidance on mobile development, and a full API reference.


![OnPeace Banner](assets/sample.png)

# OnPeace Social Platform

**Tech Stack:** Flutter, Dart, Firebase, Node.js, Agora, Real-time Systems

---

## 📝 Overview

OnPeace is a real-time social messaging platform designed for seamless, low-latency communication and privacy-first social interaction. It supports 1:1 and group chats, multimedia sharing (images, videos, GIFs), and advanced features like QR-based instant user connection, anonymous mode, and ephemeral location-based chats. The platform leverages Firebase for backend services, Node.js for session management, and Agora for high-quality voice/video calls.

---

![App Screenshot](appImage.jpg)

---

## 🚀 Key Features

- **Real-time Messaging:** 1:1 and group chats with instant delivery and low-latency communication.
- **Multimedia Sharing:** Share images, videos, and GIFs directly in chat.
- **QR-based User Connection:** Instantly connect with users via QR codes, eliminating search friction and reducing onboarding time.
- **Privacy-first Architecture:** Profile disabling and anonymous mode ensure zero user visibility when activated.
- **Voice & Video Calls:** Integrated high-quality voice and video calling using Agora.
- **Location Sharing:** Real-time location sharing in chats.
- **Ephemeral Location-based Chats:** Join nearby servers within a defined radius; all data is automatically deleted after session termination.
- **Digital Diary:** Create diary entries with public/private sharing controls for flexible content management.
- **Voice Assistant:** Perform in-app actions (messaging, calling, navigation) using voice commands.
- **Scalable Backend:** Firebase Realtime Database and Node.js backend for concurrent user management and data synchronization.

---

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version ^3.10.1 or above)
- Dart SDK (compatible with Flutter)
- A Firebase project (for backend services)
- Android Studio/Xcode/VS Code (for running on emulator/device)

### Setup Instructions

1. **Clone the repository:**
	```bash
	git clone https://github.com/rhitverse/OnPeace
	cd on_peace
	```
2. **Install dependencies:**
	```bash
	flutter pub get
	```
3. **Firebase Setup:**
	- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
	- Add Android/iOS apps to your Firebase project.
	- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective platform folders (`android/app/`, `ios/Runner/`).
	- Update `firebase_options.dart` using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
	- Ensure your `firebase.json` and `firebase_options.dart` are correctly configured.
4. **Run the app:**
	```bash
	flutter run
	```

---

## 🔗 Firebase & Backend Integration

- **Authentication:** Email/password, Google Sign-In
- **Realtime Database:** Chats, users, ephemeral sessions
- **Storage:** Media uploads (images, audio, video)
- **Messaging:** Push notifications
- **Session Management:** Node.js backend for concurrent users and scalable data sync
- **Voice/Video Calls:** Agora SDK integration

Firebase is initialized in `main.dart` using `firebase_options.dart`.

---

## 🏗️ Architecture Overview

The project follows a modular, scalable architecture with clear separation of concerns:

- **State Management:** Riverpod & Provider
- **Routing:** go_router
- **Feature-first structure:** Each feature (chat, calls, diary, etc.) is in its own folder
- **Core Layer:** Common providers, repositories, and controllers
- **Common Layer:** Shared utilities, services, and enums

### Main Folders

```
lib/
  common/         # Shared utilities, services, enums
  core/           # Providers, repositories, controllers
  features/       # Feature modules (app, auth, etc.)
  models/         # Data models
  responsive/     # Responsive UI helpers
  router/         # App routing
  screens/        # UI screens (calls, chat, diary, etc.)
  secret/         # Secret keys/configs (not committed)
  widgets/        # Reusable widgets
  main.dart       # App entry point
  firebase_options.dart # Firebase config
```

---

## 📁 Folder Structure

```
on_peace/
├── android/                  # Android native code & config
├── ios/                      # iOS native code & config
├── lib/
│   ├── common/               # Shared code (encryption, utils, etc.)
│   ├── core/                 # App-wide providers, repositories
│   ├── features/             # Feature modules (app, auth, etc.)
│   ├── models/               # Data models
│   ├── responsive/           # Responsive UI helpers
│   ├── router/               # Routing setup
│   ├── screens/              # Main UI screens
│   ├── secret/               # Secrets (excluded from VCS)
│   ├── widgets/              # Reusable widgets
│   ├── main.dart             # App entry
│   └── firebase_options.dart # Firebase config
├── assets/                   # Images, audio, SVGs
├── test/                     # Unit/widget tests
├── pubspec.yaml              # Dependencies
├── firebase.json             # Firebase config
└── README.md                 # Project info
```

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

This project is licensed under the MIT License.

---

## 🚀 Features

- Real-time chat and group messaging
- Audio/video calls (Agora integration)
- Diary and notes
- Push notifications
- Media sharing (images, audio, video)
- Location sharing (Google Maps)
- User authentication (Email, Google Sign-In)
- Profile management
- End-to-end encryption for messages

---

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version ^3.10.1 or above)
- Dart SDK (compatible with Flutter)
- A Firebase project (for backend services)
- Android Studio/Xcode/VS Code (for running on emulator/device)

### Setup Instructions

1. **Clone the repository:**
	```bash
	git clone <repo-url>
	cd on_peace
	```
2. **Install dependencies:**
	```bash
	flutter pub get
	```
3. **Firebase Setup:**
	- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
	- Add Android/iOS apps to your Firebase project.
	- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective platform folders (`android/app/`, `ios/Runner/`).
	- Update `firebase_options.dart` using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
	- Ensure your `firebase.json` and `firebase_options.dart` are correctly configured.
4. **Run the app:**
	```bash
	flutter run
	```

---

## 🔗 Firebase Integration

OnPeace uses Firebase for:
- **Authentication:** Email/password, Google Sign-In
- **Cloud Firestore:** Real-time database for chats, users, etc.
- **Firebase Storage:** Media uploads (images, audio, video)
- **Firebase Messaging:** Push notifications
- **Cloud Functions:** (if enabled)

Firebase is initialized in `main.dart` using `firebase_options.dart`.

---

## 🏗️ Architecture Overview

The project follows a modular, scalable architecture with clear separation of concerns:

- **State Management:** Riverpod & Provider
- **Routing:** go_router
- **Feature-first structure:** Each feature (chat, calls, diary, etc.) is in its own folder
- **Core Layer:** Common providers, repositories, and controllers
- **Common Layer:** Shared utilities, services, and enums

### Main Folders

```
lib/
  common/         # Shared utilities, services, enums
  core/           # Providers, repositories, controllers
  features/       # Feature modules (app, auth, etc.)
  models/         # Data models
  responsive/     # Responsive UI helpers
  router/         # App routing
  screens/        # UI screens (calls, chat, diary, etc.)
  secret/         # Secret keys/configs (not committed)
  widgets/        # Reusable widgets
  main.dart       # App entry point
  firebase_options.dart # Firebase config
```

---

## 📁 Folder Structure

```
on_peace/
├── android/                  # Android native code & config
├── ios/                      # iOS native code & config
├── lib/
│   ├── common/               # Shared code (encryption, utils, etc.)
│   ├── core/                 # App-wide providers, repositories
│   ├── features/             # Feature modules (app, auth, etc.)
│   ├── models/               # Data models
│   ├── responsive/           # Responsive UI helpers
│   ├── router/               # Routing setup
│   ├── screens/              # Main UI screens
│   ├── secret/               # Secrets (excluded from VCS)
│   ├── widgets/              # Reusable widgets
│   ├── main.dart             # App entry
│   └── firebase_options.dart # Firebase config
├── assets/                   # Images, audio, SVGs
├── test/                     # Unit/widget tests
├── pubspec.yaml              # Dependencies
├── firebase.json             # Firebase config
└── README.md                 # Project info
```
