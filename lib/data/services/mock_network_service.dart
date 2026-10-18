import '../../domain/entities/network_adapter.dart';
import '../../domain/services/i_network_service.dart';

/// In-memory mock implementation of [INetworkService] for deterministic
/// unit/widget tests and development across non-Windows operating systems.
class MockNetworkService implements INetworkService {
  bool isAdmin = true;

  final Map<String, List<String>> _dnsMap = {
    'Wi-Fi': ['1.1.1.1', '1.0.0.1'],
    'Ethernet': [],
  };

  @override
  Future<bool> isAdministrator() async => isAdmin;

  @override
  Future<List<NetworkAdapter>> getAdapters() async {
    return [
      NetworkAdapter(
        name: 'Wi-Fi',
        interfaceDescription: 'Intel(R) Wi-Fi 6 AX200 160MHz',
        isUp: true,
        isDhcp: _dnsMap['Wi-Fi']!.isEmpty,
        ipv4Addresses: const ['192.168.1.105'],
        ipv6Addresses: const ['fe80::1'],
        dnsServers: _dnsMap['Wi-Fi'] ?? const [],
      ),
      NetworkAdapter(
        name: 'Ethernet',
        interfaceDescription: 'Realtek PCIe GbE Family Controller',
        isUp: true,
        isDhcp: _dnsMap['Ethernet']!.isEmpty,
        ipv4Addresses: const ['192.168.1.120'],
        ipv6Addresses: const [],
        dnsServers: _dnsMap['Ethernet'] ?? const [],
      ),
    ];
  }

  @override
  Future<List<String>> getCurrentDns(String adapterName) async {
    return _dnsMap[adapterName] ?? [];
  }

  @override
  Future<void> setDns(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  ) async {
    _dnsMap[adapterName] = [...ipv4, ...ipv6];
  }

  @override
  Future<void> restoreDns(String adapterName) async {
    _dnsMap[adapterName] = [];
  }

  @override
  Future<void> flushDnsCache() async {
    // In-memory no-op
  }

  @override
  Future<int?> pingHost(
    String host, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (host.contains('1.1.1.1')) return 14;
    if (host.contains('8.8.8.8')) return 22;
    if (host.contains('9.9.9.9')) return 28;
    return 35;
  }
}
