import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/firebase_repositories.dart';
import 'domain/models.dart';
import 'domain/repositories.dart';

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
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.flash_on, color: Color(0xfff47b20), size: 34),
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
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'FlashDial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
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

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.profile,
    required this.devices,
    required this.onSignOut,
  });
  final UserProfile profile;
  final List<AuthorizedDevice> devices;
  final Future<void> Function() onSignOut;
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late AuthorizedDevice selected;
  @override
  void initState() {
    super.initState();
    selected = widget.devices.first;
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.devices.contains(selected)) selected = widget.devices.first;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        return Row(
          children: [
            if (!narrow) const _Sidebar(),
            Expanded(
              child: Column(
                children: [
                  _Header(profile: widget.profile, onSignOut: widget.onSignOut),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(narrow ? 20 : 36),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Monitor the Android device authorized for your account.',
                            ),
                            const SizedBox(height: 28),
                            if (widget.devices.length > 1) ...[
                              DropdownButton<AuthorizedDevice>(
                                value: selected,
                                isExpanded: true,
                                items: widget.devices
                                    .map(
                                      (device) => DropdownMenuItem(
                                        value: device,
                                        child: Text(device.deviceId),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (device) {
                                  if (device != null) {
                                    setState(() => selected = device);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            _DeviceCard(device: selected),
                            const SizedBox(height: 24),
                            const _ComingSoonCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();
  @override
  Widget build(BuildContext context) => Container(
    width: 232,
    color: const Color(0xff10233f),
    padding: const EdgeInsets.all(20),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FlashDial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 48),
        ListTile(
          selected: true,
          selectedTileColor: Color(0xff203657),
          iconColor: Colors.white,
          textColor: Colors.white,
          leading: Icon(Icons.grid_view_rounded),
          title: Text('Overview'),
        ),
        ListTile(
          enabled: false,
          leading: Icon(Icons.phone_in_talk_outlined),
          title: Text('Dialer'),
        ),
        Spacer(),
        Text(
          'CALL CONTROLS COMING NEXT',
          style: TextStyle(
            color: Color(0xff71839b),
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onSignOut});
  final UserProfile profile;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    color: Colors.white,
    child: Row(
      children: [
        const Spacer(),
        const Icon(Icons.circle, size: 9, color: Color(0xff39c6b5)),
        const SizedBox(width: 8),
        const Text('Device connection live'),
        const SizedBox(width: 24),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'signout') onSignOut();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
          child: CircleAvatar(
            backgroundColor: const Color(0xffe6eef8),
            child: Text(
              (profile.email.isEmpty ? 'U' : profile.email[0]).toUpperCase(),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final AuthorizedDevice device;
  @override
  Widget build(BuildContext context) {
    final online = device.connectionState == DeviceConnectionState.online;
    final stale = device.connectionState == DeviceConnectionState.stale;
    final stateColor = online
        ? const Color(0xff14866f)
        : stale
        ? const Color(0xffb66b08)
        : const Color(0xff778398);
    final label =
        device.connectionState.name[0].toUpperCase() +
        device.connectionState.name.substring(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.phone_android_rounded,
                  size: 40,
                  color: Color(0xfff47b20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Android device',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        device.deviceId,
                        style: const TextStyle(color: Color(0xff778398)),
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            Wrap(
              spacing: 36,
              runSpacing: 20,
              children: [
                _Detail(
                  label: 'Platform',
                  value: device.platform.toUpperCase(),
                ),
                _Detail(label: 'App ID', value: device.appId),
                _Detail(
                  label: 'Last seen',
                  value: _formatDate(device.lastSeenAt),
                ),
              ],
            ),
            if (stale)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'This heartbeat is older than 2 minutes. Presence is shown as stale until the phone reports again.',
                  style: TextStyle(color: Color(0xff9a620d)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            color: Color(0xff778398),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.construction_outlined, color: Color(0xff14866f)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remote calling controls',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Dialing and call controls will appear once the mobile command contract is ready.',
                  style: TextStyle(color: Color(0xff778398)),
                ),
              ],
            ),
          ),
          Chip(label: Text('Coming next')),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime? value) => value == null
    ? 'Unknown'
    : '${value.toLocal().day.toString().padLeft(2, '0')}/${value.toLocal().month.toString().padLeft(2, '0')}/${value.toLocal().year} ${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
