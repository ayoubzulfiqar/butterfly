/// Immutable representation of a network adapter interface.
class NetworkAdapter {
  final String name;
  final String interfaceDescription;
  final bool isUp;
  final bool isDhcp;
  final List<String> ipv4Addresses;
  final List<String> ipv6Addresses;
  final List<String> dnsServers;

  const NetworkAdapter({
    required this.name,
    required this.interfaceDescription,
    required this.isUp,
    required this.isDhcp,
    required this.ipv4Addresses,
    required this.ipv6Addresses,
    required this.dnsServers,
  });

  bool get hasDnsConfigured => dnsServers.isNotEmpty;

  String get formattedDns {
    if (dnsServers.isEmpty) {
      return 'Automatic (DHCP)';
    }
    return dnsServers.join(', ');
  }

  String get primaryIp {
    if (ipv4Addresses.isNotEmpty) {
      return ipv4Addresses.first;
    }
    if (ipv6Addresses.isNotEmpty) {
      return ipv6Addresses.first;
    }
    return 'No IP assigned';
  }
}
