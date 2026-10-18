/// Immutable representation of a network adapter interface.
class NetworkAdapter {
  final String name;
  final String interfaceDescription;
  final bool isUp;
  final bool _interfaceDhcp;
  final List<String> ipv4Addresses;
  final List<String> ipv6Addresses;
  final List<String> dnsServers;

  const NetworkAdapter({
    required this.name,
    required this.interfaceDescription,
    required this.isUp,
    bool isDhcp = true,
    required this.ipv4Addresses,
    required this.ipv6Addresses,
    required this.dnsServers,
  }) : _interfaceDhcp = isDhcp;

  /// True if DNS is automatically obtained via DHCP (no static DNS configured).
  bool get isDhcp => dnsServers.isEmpty;

  /// True if interface IP itself is configured via DHCP.
  bool get isInterfaceDhcp => _interfaceDhcp;

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
