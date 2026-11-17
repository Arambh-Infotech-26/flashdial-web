import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/data/firebase_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    FlashDialApp(
      authRepository: FirebaseAuthRepository(),
      authorizationRepository: FirebaseAuthorizationRepository(),
      deviceRepository: FirebaseDeviceRepository(),
    ),
  );
}
