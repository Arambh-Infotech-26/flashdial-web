import 'models.dart';

abstract interface class AuthRepository {
  Stream<Object?> watchAuthState();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

abstract interface class AuthorizationRepository {
  Stream<UserProfile?> watchCurrentProfile(String uid);
}

abstract interface class DeviceRepository {
  Stream<List<AuthorizedDevice>> watchAuthorizedDevices(String uid);
}
