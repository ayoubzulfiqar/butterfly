import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/network_adapter.dart';
import 'package:butterfly/data/services/dns_safety_net_service_impl.dart';
import 'package:butterfly/data/services/mock_network_service.dart';

void main() {
  group('DnsSafetyNetService Snapshot and Restoration Tests', () {
    late Directory tempDir;
    late File stateFile;
    late DnsSafetyNetServiceImpl safetyNet;
    late MockNetworkService mockNetwork;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('butterfly_safety_net_test_');
      stateFile = File('${tempDir.path}/state.json');
      safetyNet = DnsSafetyNetServiceImpl(stateFile: stateFile);
      mockNetwork = MockNetworkService();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('snapshotCurrentDns serializes adapter state to disk', () async {
      final adapter = NetworkAdapter(
        name: 'Ethernet',
        interfaceDescription: 'Physical adapter',
        isUp: true,
        isDhcp: false,
        ipv4Addresses: const ['192.168.1.50'],
        ipv6Addresses: const [],
        dnsServers: const ['192.168.1.1', '192.168.1.254'],
      );

      await safetyNet.snapshotCurrentDns(adapter);

      expect(stateFile.existsSync(), isTrue);
      expect(await safetyNet.hasPendingRestore(), isTrue);

      final snapshot = await safetyNet.readSnapshot();
      expect(snapshot, isNotNull);
      expect(snapshot!.interfaceName, equals('Ethernet'));
      expect(snapshot.isDhcp, isFalse);
      expect(snapshot.dnsServers, equals(['192.168.1.1', '192.168.1.254']));
    });

    test('restoreOriginalDns reapplies original static DNS and deletes state.json', () async {
      final adapter = NetworkAdapter(
        name: 'Wi-Fi',
        interfaceDescription: 'Wireless adapter',
        isUp: true,
        isDhcp: false,
        ipv4Addresses: const ['192.168.1.100'],
        ipv6Addresses: const [],
        dnsServers: const ['1.1.1.1', '1.0.0.1'],
      );

      await safetyNet.snapshotCurrentDns(adapter);
      expect(await safetyNet.hasPendingRestore(), isTrue);

      // Mutate network to a custom DNS server
      await mockNetwork.setDns('Wi-Fi', ['8.8.8.8'], []);
      expect(await mockNetwork.getCurrentDns('Wi-Fi'), equals(['8.8.8.8']));

      final restored = await safetyNet.restoreOriginalDns(mockNetwork);

      expect(restored, isTrue);
      expect(await mockNetwork.getCurrentDns('Wi-Fi'), equals(['1.1.1.1', '1.0.0.1']));
      expect(stateFile.existsSync(), isFalse);
      expect(await safetyNet.hasPendingRestore(), isFalse);
    });

    test('restoreOriginalDns reverts to DHCP when snapshot was automatic', () async {
      final adapter = NetworkAdapter(
        name: 'Ethernet',
        interfaceDescription: 'Physical adapter',
        isUp: true,
        isDhcp: true,
        ipv4Addresses: const ['192.168.1.120'],
        ipv6Addresses: const [],
        dnsServers: const [],
      );

      await safetyNet.snapshotCurrentDns(adapter);

      // Mutate network to static
      await mockNetwork.setDns('Ethernet', ['9.9.9.9'], []);
      expect(await mockNetwork.getCurrentDns('Ethernet'), equals(['9.9.9.9']));

      final restored = await safetyNet.restoreOriginalDns(mockNetwork);

      expect(restored, isTrue);
      expect(await mockNetwork.getCurrentDns('Ethernet'), isEmpty);
      expect(stateFile.existsSync(), isFalse);
    });

    test('readSnapshot handles corrupt or empty state.json gracefully without crashing', () async {
      stateFile.writeAsStringSync('{ corrupt json content ... !@#\$%^&*(');

      expect(await safetyNet.hasPendingRestore(), isTrue);
      final snapshot = await safetyNet.readSnapshot();

      expect(snapshot, isNull);
      await safetyNet.clearSnapshot();
      expect(stateFile.existsSync(), isFalse);
    });
  });
}
