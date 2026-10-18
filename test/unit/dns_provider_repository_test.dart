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
}
