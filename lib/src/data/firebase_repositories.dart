import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  @override
  Stream<User?> watchAuthState() => _auth.authStateChanges();
  @override
  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  @override
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseAuthorizationRepository implements AuthorizationRepository {
  FirebaseAuthorizationRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;
  final FirebaseDatabase _database;
  @override
  Stream<UserProfile?> watchCurrentProfile(String uid) =>
      _database.ref('users/$uid').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return null;
        return UserProfile.fromMap(uid, Map<Object?, Object?>.from(value));
      });
}

class FirebaseDeviceRepository implements DeviceRepository {
  FirebaseDeviceRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;
  final FirebaseDatabase _database;
  @override
  Stream<List<AuthorizedDevice>> watchAuthorizedDevices(String uid) =>
      _database.ref('users/$uid/devices').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <AuthorizedDevice>[];
        return value.entries
            .where((entry) => entry.value is Map)
            .map(
              (entry) => AuthorizedDevice.fromMap(
                entry.key.toString(),
                Map<Object?, Object?>.from(entry.value as Map),
              ),
            )
            .toList();
      });
}

String readableAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' => 'Google sign-in was cancelled.',
      'too-many-requests' => 'Too many attempts. Try again in a little while.',
      _ => 'We could not sign you in. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}
