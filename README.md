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

After completing mobile setup, tap **Start service**. The mobile app creates the profile for a new Firebase account or refreshes the existing active profile, replaces older device records for that account, and starts its live presence heartbeat. The web app can then sign in with the same Firebase account and display the phone.

Deploy `database.rules.json` with the Firebase CLI after reviewing the mobile bootstrap policy. New mobile profiles are created as `role: user` and `status: active`; existing role and status values cannot be changed by the mobile client. Device identity remains fixed to Android FlashDial records, and older devices are replaced when service is started on a new phone.

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
