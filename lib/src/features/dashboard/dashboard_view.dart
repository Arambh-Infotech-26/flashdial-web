part of '../../app.dart';

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
