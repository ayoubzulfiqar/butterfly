import 'dart:convert';
import 'dart:io';

import '../../core/utils/logger.dart';
import '../../domain/entities/network_adapter.dart';
import '../../domain/services/i_network_service.dart';

class LinuxNetworkService implements INetworkService {
  static final RegExp _validInterfaceRegex = RegExp(r'^[a-zA-Z0-9_\-\.:]+$');
  static final RegExp _validIpRegex = RegExp(
    r'^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[a-fA-F0-9:]+$',
  );

  static void validateInterfaceName(String name) {
    if (!_validInterfaceRegex.hasMatch(name.trim())) {
      throw ArgumentError(
        'Invalid interface name: $name (contains disallowed characters)',
      );
    }
  }

  static void validateIpAddress(String ip) {
    final trimmed = ip.trim();
    if (!_validIpRegex.hasMatch(trimmed) ||
        InternetAddress.tryParse(trimmed) == null) {
      throw ArgumentError('Invalid IP address: $ip');
    }
  }

  static String buildSetDnsCommand(
    String adapterName,
    List<String> dnsServers,
  ) {
    validateInterfaceName(adapterName);
    for (final ip in dnsServers) {
      validateIpAddress(ip);
    }
    final sanitizedServers = dnsServers.map((s) => s.trim()).join(' ');
    return 'resolvectl dns ${adapterName.trim()} $sanitizedServers';
  }

  static String buildResetDnsCommand(String adapterName) {
    validateInterfaceName(adapterName);
    return 'resolvectl revert ${adapterName.trim()}';
  }

  static String buildFlushCacheCommand() {
    return 'resolvectl flush-caches';
  }

  static List<NetworkAdapter> parseAdaptersFromOutput({
    required String ipLinkJson,
    required String resolvectlDnsOutput,
  }) {
    final Map<String, List<String>> dnsMap = {};
    for (final line in resolvectlDnsOutput.split('\n')) {
      final trimmed = line.trim();
      final match =
          RegExp(r'^Link\s+\d+\s*\(([^)]+)\):\s*(.*)$').firstMatch(trimmed);
      if (match != null) {
        final ifName = match.group(1)?.trim() ?? '';
        final rawServers = match.group(2)?.trim() ?? '';
        if (ifName.isNotEmpty) {
          final servers = rawServers
              .split(RegExp(r'\s+'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && InternetAddress.tryParse(s) != null)
              .toList();
          dnsMap[ifName] = servers;
        }
      }
    }

    final List<NetworkAdapter> adapters = [];
    try {
      final decoded = jsonDecode(ipLinkJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final ifname = item['ifname'] as String? ?? '';
            final linkType = item['link_type'] as String? ?? '';
            final operstate = item['operstate'] as String? ?? 'DOWN';

            if (ifname.isEmpty || ifname == 'lo' || linkType == 'loopback') {
              continue;
            }

            final flags = (item['flags'] as List?)
                    ?.map((f) => f.toString().toUpperCase())
                    .toList() ??
                [];
            final isUp = operstate.toUpperCase() == 'UP' || flags.contains('UP');
            final dnsServers = dnsMap[ifname] ?? const [];

            final List<String> ipv4 = [];
            final List<String> ipv6 = [];
            final addrInfo = item['addr_info'];
            if (addrInfo is List) {
              for (final addr in addrInfo) {
                if (addr is Map<String, dynamic>) {
                  final family = addr['family'] as String? ?? '';
                  final local = addr['local'] as String? ?? '';
                  if (local.isNotEmpty) {
                    if (family == 'inet') {
                      ipv4.add(local);
                    } else if (family == 'inet6') {
                      ipv6.add(local);
                    }
                  }
                }
              }
            }

            adapters.add(
              NetworkAdapter(
                name: ifname,
                interfaceDescription: '$ifname ($linkType)',
                isUp: isUp,
                isDhcp: dnsServers.isEmpty,
                ipv4Addresses: ipv4,
                ipv6Addresses: ipv6,
                dnsServers: dnsServers,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return adapters;
  }

  @override
  Future<bool> isAdministrator() async {
    try {
      final id = await Process.run('id', ['-u']);
      return id.exitCode == 0 && id.stdout.toString().trim() == '0';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<NetworkAdapter>> getAdapters() async {
    appLogger.info(
      'LinuxNetworkService',
      'Discovering network adapters via ip and resolvectl',
    );
    try {
      final linkResult = await Process.run('ip', ['-j', 'addr']);
      final dnsResult = await Process.run('resolvectl', ['dns']);

      final adapters = parseAdaptersFromOutput(
        ipLinkJson: linkResult.stdout.toString(),
        resolvectlDnsOutput: dnsResult.stdout.toString(),
      );

      appLogger.info(
        'LinuxNetworkService',
        'Discovered ${adapters.length} network adapters',
      );
      return adapters;
    } catch (e, st) {
      appLogger.severe(
        'LinuxNetworkService',
        'Failed to query Linux network interfaces: $e',
        st,
      );
      return [];
    }
  }

  @override
  Future<List<String>> getCurrentDns(String adapterName) async {
    try {
      final dnsResult = await Process.run('resolvectl', ['dns', adapterName]);
      final output = dnsResult.stdout.toString();
      final regex = RegExp(r'^Link\s+\d+\s*\([^)]+\):\s*(.*)$', multiLine: true);
      final match = regex.firstMatch(output);
      if (match != null) {
        return (match.group(1) ?? '')
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty && InternetAddress.tryParse(s) != null)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> setDns(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  ) async {
    final allIps = [...ipv4, ...ipv6];
    final command = buildSetDnsCommand(adapterName, allIps);
    appLogger.info('LinuxNetworkService', 'Applying DNS: $command');

    var result = await Process.run('sh', ['-c', command]);
    if (result.exitCode != 0) {
      appLogger.warning(
        'LinuxNetworkService',
        'Standard resolvectl failed, elevating with pkexec',
      );
      result = await Process.run('pkexec', ['sh', '-c', command]);
    }

    if (result.exitCode == 0) {
      appLogger.info('LinuxNetworkService', 'DNS applied successfully');
      await flushDnsCache();
    } else {
      final err = 'resolvectl exited with code ${result.exitCode}: ${result.stderr}';
      appLogger.severe('LinuxNetworkService', err);
      throw ProcessException('sh', ['-c', command], err, result.exitCode);
    }
  }

  @override
  Future<void> restoreDns(String adapterName) async {
    final command = buildResetDnsCommand(adapterName);
    appLogger.info('LinuxNetworkService', 'Restoring automatic DNS: $command');

    var result = await Process.run('sh', ['-c', command]);
    if (result.exitCode != 0) {
      result = await Process.run('pkexec', ['sh', '-c', command]);
    }

    if (result.exitCode == 0) {
      appLogger.info('LinuxNetworkService', 'DHCP restored successfully');
      await flushDnsCache();
    } else {
      final err = 'resolvectl revert failed: ${result.stderr}';
      appLogger.severe('LinuxNetworkService', err);
      throw ProcessException('sh', ['-c', command], err, result.exitCode);
    }
  }

  @override
  Future<void> flushDnsCache() async {
    try {
      final command = buildFlushCacheCommand();
      await Process.run('sh', ['-c', command]);
    } catch (_) {}
  }

  @override
  Future<int?> pingHost(
    String host, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        53,
        timeout: timeout,
      );
      sw.stop();
      await socket.close();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }
}
