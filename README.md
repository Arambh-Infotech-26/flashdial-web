# FlashDial Web

Browser-first Flutter dashboard for approved FlashDial users. This milestone provides Firebase email/password and Google sign-in, password reset, authorization checks, live Android device presence, and a responsive dashboard shell.

Remote dialing and call controls are intentionally deferred until FlashDial Mobile exposes and consumes a validated command contract.

## Firebase setup

Enable Email/Password and Google providers in the existing Firebase project. Approved users and their profiles are provisioned by trusted admin/backend operations; there is no public registration flow.

Profiles and presence are read from:

```text
users/{uid}
users/{uid}/devices/{deviceId}
```

Deploy `database.rules.json` with the Firebase CLI after reviewing the temporary mobile presence write rule. It only permits updates to an existing device record and keeps platform/app identity immutable. User roles, account status, and device authorization remain trusted-admin responsibilities.

## Run

```bash
flutter pub get
flutter run -d chrome
```

Device presence is marked stale after two minutes without a recent heartbeat. The app never treats an old `isOnline` value as live indefinitely.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
