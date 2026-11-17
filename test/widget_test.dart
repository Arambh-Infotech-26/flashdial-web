import 'package:flutter_test/flutter_test.dart';

import 'package:flashdial_web/src/domain/models.dart';

void main() {
  group('AuthorizedDevice connection state', () {
    final now = DateTime(2026, 11, 17, 12);

    test('maps a recent online heartbeat to online', () {
      final device = AuthorizedDevice.fromMap('pixel', {
        'platform': 'android',
        'appId': 'com.at.flashdial',
        'isOnline': true,
        'lastSeenAt': now.millisecondsSinceEpoch - 30 * 1000,
      }, now: now);
      expect(device.connectionState, DeviceConnectionState.online);
    });

    test('distinguishes stale and offline devices', () {
      final stale = AuthorizedDevice.fromMap('pixel', {
        'isOnline': true,
        'lastSeenAt': now.millisecondsSinceEpoch - 121 * 1000,
      }, now: now);
      final offline = AuthorizedDevice.fromMap('pixel', {
        'isOnline': false,
      }, now: now);
      expect(stale.connectionState, DeviceConnectionState.stale);
      expect(offline.connectionState, DeviceConnectionState.offline);
    });

    test('keeps missing timestamp unknown while online', () {
      final device = AuthorizedDevice.fromMap('pixel', {
        'isOnline': true,
      }, now: now);
      expect(device.connectionState, DeviceConnectionState.unknown);
    });
  });

  test('parses account profile authorization fields', () {
    final profile = UserProfile.fromMap('uid-1', {
      'email': 'user@example.com',
      'role': 'user',
      'status': 'active',
    });
    expect(profile.uid, 'uid-1');
    expect(profile.role, AccountRole.user);
    expect(profile.status, AccountStatus.active);
  });
}
