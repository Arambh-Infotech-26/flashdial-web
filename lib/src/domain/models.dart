enum AccountRole { user, admin, unknown }

enum AccountStatus { invited, active, suspended, disabled, unknown }

enum DeviceConnectionState { online, offline, stale, unknown }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
  });
  final String uid;
  final String email;
  final AccountRole role;
  final AccountStatus status;

  factory UserProfile.fromMap(String uid, Map<Object?, Object?> map) =>
      UserProfile(
        uid: uid,
        email: map['email'] as String? ?? '',
        role: switch (map['role']) {
          'user' => AccountRole.user,
          'admin' => AccountRole.admin,
          _ => AccountRole.unknown,
        },
        status: switch (map['status']) {
          'invited' => AccountStatus.invited,
          'active' => AccountStatus.active,
          'suspended' => AccountStatus.suspended,
          'disabled' => AccountStatus.disabled,
          _ => AccountStatus.unknown,
        },
      );
}

class AuthorizedDevice {
  const AuthorizedDevice({
    required this.deviceId,
    required this.platform,
    required this.appId,
    required this.isOnline,
    required this.lastSeenAt,
    required this.connectionState,
  });
  final String deviceId;
  final String platform;
  final String appId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DeviceConnectionState connectionState;

  factory AuthorizedDevice.fromMap(
    String deviceId,
    Map<Object?, Object?> map, {
    DateTime? now,
  }) {
    final lastSeen = _dateFrom(map['lastSeenAt']);
    final current = now ?? DateTime.now();
    final recent =
        lastSeen != null &&
        current.difference(lastSeen).inSeconds <= 120 &&
        !current.isBefore(lastSeen);
    final online = map['isOnline'] == true;
    final state = online && recent
        ? DeviceConnectionState.online
        : online && lastSeen != null
        ? DeviceConnectionState.stale
        : online
        ? DeviceConnectionState.unknown
        : DeviceConnectionState.offline;
    return AuthorizedDevice(
      deviceId: deviceId,
      platform: map['platform'] as String? ?? 'unknown',
      appId: map['appId'] as String? ?? 'unknown',
      isOnline: online,
      lastSeenAt: lastSeen,
      connectionState: state,
    );
  }

  static DateTime? _dateFrom(Object? value) =>
      value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;
}
