import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/network_adapter.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';
import 'package:butterfly/domain/entities/dpi_bypass_mode.dart';
import 'package:butterfly/domain/entities/app_log_entry.dart';
import 'package:butterfly/core/utils/logger.dart';

void main() {
  test('NetworkAdapter correctly formats DNS summary', () {
    const adapter = NetworkAdapter(
      name: 'Wi-Fi',
      interfaceDescription: 'Intel Wi-Fi 6',
      isUp: true,
      isDhcp: false,
      ipv4Addresses: ['192.168.1.50'],
      ipv6Addresses: [],
      dnsServers: ['1.1.1.1', '1.0.0.1'],
    );
    expect(adapter.hasDnsConfigured, isTrue);
    expect(adapter.formattedDns, '1.1.1.1, 1.0.0.1');
  });

  test('NetworkAdapter formats empty DNS as Automatic (DHCP)', () {
    const adapter = NetworkAdapter(
      name: 'Ethernet',
      interfaceDescription: 'Realtek Gaming GbE',
      isUp: true,
      isDhcp: true,
      ipv4Addresses: ['192.168.1.100'],
      ipv6Addresses: [],
      dnsServers: [],
    );
    expect(adapter.hasDnsConfigured, isFalse);
    expect(adapter.formattedDns, 'Automatic (DHCP)');
  });

  test('DnsProvider category and security tags', () {
    const provider = DnsProvider(
      id: 'cloudflare',
      name: 'Cloudflare',
      description: 'Privacy-first DNS',
      category: DnsCategory.privacy,
      features: ['No Logs', 'DNSSEC'],
      ipv4: ['1.1.1.1', '1.0.0.1'],
      ipv6: ['2606:4700:4700::1111', '2606:4700:4700::1001'],
    );
    expect(provider.isCustom, isFalse);
    expect(provider.features.length, 2);
  });

  test('AppLogger dispatches log entries to broadcast stream', () async {
    final entries = <AppLogEntry>[];
    final sub = appLogger.logStream.listen(entries.add);
    appLogger.info('Test', 'Hello Logger');
    await Future.delayed(const Duration(milliseconds: 20));
    expect(entries.any((e) => e.message == 'Hello Logger'), isTrue);
    await sub.cancel();
  });
}
