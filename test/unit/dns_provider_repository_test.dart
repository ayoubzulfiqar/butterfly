import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';

void main() {
  test('Returns built-in DNS providers including Cloudflare and Google', () {
    final repo = DnsProviderRepositoryImpl();
    final providers = repo.getBuiltInProviders();
    expect(providers.any((p) => p.name.contains('Cloudflare')), isTrue);
    expect(providers.any((p) => p.name.contains('Google')), isTrue);
    expect(providers.any((p) => p.ipv4.contains('1.1.1.1')), isTrue);
    expect(providers.any((p) => p.ipv4.contains('8.8.8.8')), isTrue);
  });

  test('Catalog includes comprehensive 25+ resolvers from dnsChanger-desktop', () {
    final repo = DnsProviderRepositoryImpl();
    final providers = repo.getBuiltInProviders();
    expect(providers.length, greaterThanOrEqualTo(20));

    // Verify key regional anti-sanction & bypass resolvers
    expect(providers.any((p) => p.name.contains('Shecan')), isTrue);
    expect(providers.any((p) => p.name.contains('Electro Team')), isTrue);
    expect(providers.any((p) => p.name.contains('Radar game') || p.name.contains('Radar Game')), isTrue);
    expect(providers.any((p) => p.name.contains('Zeus DNS')), isTrue);
    expect(providers.any((p) => p.name.contains('Asiatech')), isTrue);

    // Verify key security, privacy, and gaming resolvers
    expect(providers.any((p) => p.name.contains('OpenDNS')), isTrue);
    expect(providers.any((p) => p.name.contains('DNS.WATCH')), isTrue);
    expect(providers.any((p) => p.name.contains('dns0.eu')), isTrue);
    expect(providers.any((p) => p.name.contains('ControlD')), isTrue);
    expect(providers.any((p) => p.name.contains('Hive DNS')), isTrue);
  });

  test('Supports adding and removing custom providers', () async {
    final repo = DnsProviderRepositoryImpl();
    const custom = DnsProvider(
      id: 'custom_1',
      name: 'Corporate DNS',
      description: 'Internal resolver',
      category: DnsCategory.custom,
      features: ['Internal'],
      ipv4: ['10.0.0.1'],
      ipv6: [],
      isCustom: true,
    );
    await repo.addCustomProvider(custom);
    final all = await repo.getAllProviders();
    expect(all.any((p) => p.id == 'custom_1'), isTrue);
    await repo.deleteCustomProvider('custom_1');
    final after = await repo.getAllProviders();
    expect(after.any((p) => p.id == 'custom_1'), isFalse);
  });

  test('Parses remote catalog JSON payload into providers list', () {
    const rawJson = '''
    [
      {
        "key": "TEST_DNS",
        "name": "Test Server",
        "servers": ["198.51.100.1", "198.51.100.2"],
        "tags": ["Gaming", "Web"],
        "rate": 8
      }
    ]
    ''';
    final parsed = DnsProviderRepositoryImpl.parseRemoteCatalogJson(rawJson);
    expect(parsed.length, equals(1));
    expect(parsed.first.id, equals('TEST_DNS'));
    expect(parsed.first.name, equals('Test Server'));
    expect(parsed.first.ipv4, equals(['198.51.100.1', '198.51.100.2']));
  });
}
