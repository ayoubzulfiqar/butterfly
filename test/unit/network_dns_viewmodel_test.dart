import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_network_service.dart';
import 'package:butterfly/data/repositories/dns_provider_repository_impl.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';
import 'package:butterfly/presentation/viewmodels/network_dns_viewmodel.dart';

void main() {
  test('NetworkDnsViewModel loads adapters and selects first adapter', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(
      networkService: netService,
      repository: repo,
    );

    await vm.loadInitialData();
    expect(vm.adapters.isNotEmpty, isTrue);
    expect(vm.selectedAdapter, isNotNull);
    expect(vm.currentDnsServers, isNotEmpty);
    expect(vm.isAdministrator, isTrue);
  });

  test('NetworkDnsViewModel applies DNS and updates state', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(
      networkService: netService,
      repository: repo,
    );
    await vm.loadInitialData();

    final cloudflare = vm.providers.firstWhere(
      (p) => p.name.contains('Cloudflare'),
    );
    final success = await vm.applyDns(cloudflare);
    expect(success, isTrue);
    expect(vm.isApplyingDns, isFalse);
    expect(vm.statusMessage, contains('Cloudflare'));
  });

  test('NetworkDnsViewModel filters providers by search query and category', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(
      networkService: netService,
      repository: repo,
    );
    await vm.loadInitialData();

    vm.setSearchQuery('Google Public');
    expect(vm.filteredProviders.length, 1);
    expect(vm.filteredProviders.first.name, contains('Google'));

    vm.setSearchQuery('');
    vm.setSelectedCategory(DnsCategory.security);
    expect(
      vm.filteredProviders.every(
        (p) => p.category == DnsCategory.security,
      ),
      isTrue,
    );
  });

  test('NetworkDnsViewModel restores DHCP', () async {
    final netService = MockNetworkService();
    final repo = DnsProviderRepositoryImpl();
    final vm = NetworkDnsViewModel(
      networkService: netService,
      repository: repo,
    );
    await vm.loadInitialData();

    await vm.restoreDhcp();
    expect(vm.currentDnsServers.isEmpty, isTrue);
    expect(vm.statusMessage, contains('DHCP'));
  });
}
