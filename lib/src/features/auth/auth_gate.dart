part of '../../app.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.authorizationRepository,
    required this.deviceRepository,
  });
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;
  final DeviceRepository deviceRepository;
  @override
  Widget build(BuildContext context) => StreamBuilder<Object?>(
    stream: authRepository.watchAuthState(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LoadingView();
      }
      final user = snapshot.data as User?;
      return user == null
          ? SignInView(authRepository: authRepository)
          : ProfileGate(
              user: user,
              authRepository: authRepository,
              authorizationRepository: authorizationRepository,
              deviceRepository: deviceRepository,
            );
    },
  );
}

class ProfileGate extends StatelessWidget {
  const ProfileGate({
    super.key,
    required this.user,
    required this.authRepository,
    required this.authorizationRepository,
    required this.deviceRepository,
  });
  final User user;
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;
  final DeviceRepository deviceRepository;
  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile?>(
    stream: authorizationRepository.watchCurrentProfile(user.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LoadingView();
      }
      final profile = snapshot.data;
      if (profile == null) {
        return AccessView(
          title: 'Account not provisioned',
          message:
              'An administrator has not provisioned a FlashDial account for this sign-in.',
          onSignOut: authRepository.signOut,
        );
      }
      if (profile.status != AccountStatus.active) {
        return AccessView(
          title: 'Account access is blocked',
          message:
              'Your account is currently ${profile.status.name}. Contact your administrator if this is unexpected.',
          onSignOut: authRepository.signOut,
        );
      }
      if (profile.role == AccountRole.unknown) {
        return AccessView(
          title: 'Role not authorized',
          message: 'Your account does not have a permitted FlashDial role.',
          onSignOut: authRepository.signOut,
        );
      }
      return DeviceGate(
        profile: profile,
        authRepository: authRepository,
        deviceRepository: deviceRepository,
      );
    },
  );
}

class DeviceGate extends StatelessWidget {
  const DeviceGate({
    super.key,
    required this.profile,
    required this.authRepository,
    required this.deviceRepository,
  });
  final UserProfile profile;
  final AuthRepository authRepository;
  final DeviceRepository deviceRepository;
  @override
  Widget build(BuildContext context) => StreamBuilder<List<AuthorizedDevice>>(
    stream: deviceRepository.watchAuthorizedDevices(profile.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LoadingView();
      }
      if (snapshot.hasError) {
        return AccessView(
          title: 'Device status unavailable',
          message: 'FlashDial could not read your authorized Android devices.',
          onSignOut: authRepository.signOut,
        );
      }
      final devices = snapshot.data ?? const <AuthorizedDevice>[];
      return devices.isEmpty
          ? AccessView(
              title: 'No Android device connected',
              message:
                  'An administrator must authorize your FlashDial Mobile device before it appears here.',
              onSignOut: authRepository.signOut,
            )
          : DashboardView(
              profile: profile,
              devices: devices,
              onSignOut: authRepository.signOut,
            );
    },
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class AccessView extends StatelessWidget {
  const AccessView({
    super.key,
    required this.title,
    required this.message,
    required this.onSignOut,
  });
  final String title;
  final String message;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phonelink_erase, size: 44),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignInView extends StatefulWidget {
  const SignInView({super.key, required this.authRepository});
  final AuthRepository authRepository;
  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool obscure = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.authRepository.signInWithEmail(email.text, password.text);
    } catch (e) {
      if (mounted) setState(() => error = readableAuthError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> google() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => error = readableAuthError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (!email.text.contains('@')) {
      setState(() => error = 'Enter your email first to reset your password.');
      return;
    }
    try {
      await widget.authRepository.sendPasswordReset(email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = readableAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 32),
          Text(
            'Welcome back',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Sign in to view your connected FlashDial device.'),
          const SizedBox(height: 28),
          TextFormField(
            controller: email,
            decoration: const InputDecoration(
              labelText: 'Work email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) => v == null || !v.contains('@')
                ? 'Enter a valid email address'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: 'Show or hide password',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy ? null : resetPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xffa83220)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Sign in'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: busy ? null : google,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (constraints.maxWidth >= 760)
              const Expanded(child: _BrandPanel()),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset('assets/flashdial-mark.png', width: 34, height: 34),
      SizedBox(width: 8),
      Text(
        'FlashDial',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xff10233f),
        ),
      ),
    ],
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xff10233f),
    padding: const EdgeInsets.all(64),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image(image: AssetImage('assets/flashdial-web-logo.png'), width: 360),
        SizedBox(height: 48),
        Text(
          'Your phone,\nconnected.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'A simple command center for your authorized Android device.',
          style: TextStyle(color: Color(0xffb9c7da), fontSize: 17, height: 1.5),
        ),
      ],
    ),
  );
}
