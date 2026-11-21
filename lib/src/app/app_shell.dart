part of '../app.dart';

class FlashDialApp extends StatelessWidget {
  const FlashDialApp({
    super.key,
    required this.authRepository,
    required this.authorizationRepository,
    required this.deviceRepository,
  });
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;
  final DeviceRepository deviceRepository;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xfff47b20))
        .copyWith(
          primary: const Color(0xfff47b20),
          secondary: const Color(0xff39c6b5),
          onSurface: const Color(0xff10233f),
        );
    return MaterialApp(
      title: 'FlashDial Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xfff5f7fb),
        useMaterial3: true,
      ),
      home: AuthGate(
        authRepository: authRepository,
        authorizationRepository: authorizationRepository,
        deviceRepository: deviceRepository,
      ),
    );
  }
}
