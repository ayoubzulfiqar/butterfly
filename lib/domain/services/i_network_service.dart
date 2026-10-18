import '../entities/network_adapter.dart';

/// Contract for operating system network and DNS configuration services.
abstract class INetworkService {
  /// Checks whether the running process has elevated administrator privileges.
  Future<bool> isAdministrator();

  /// Retrieves list of active network adapter interfaces on the host.
  Future<List<NetworkAdapter>> getAdapters();

  /// Retrieves currently configured DNS server addresses for [adapterName].
  Future<List<String>> getCurrentDns(String adapterName);

  /// Configures both IPv4 and IPv6 DNS addresses for [adapterName] atomically.
  Future<void> setDns(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  );

  /// Restores DNS settings to DHCP (automatic) for [adapterName].
  Future<void> restoreDns(String adapterName);

  /// Flushes system DNS resolver cache to apply changes immediately.
  Future<void> flushDnsCache();

  /// Measures round-trip ICMP or DNS socket ping latency in milliseconds.
  Future<int?> pingHost(String host, {Duration timeout = const Duration(seconds: 2)});
}
