import 'dart:async';
import 'dart:io';
import '../../core/utils/logger.dart';
import '../../domain/entities/network_adapter.dart';
import '../../domain/services/i_network_service.dart';

/// Implementation of [INetworkService] on Windows using PowerShell and netsh.
class WindowsNetworkService implements INetworkService {
  /// Escapes double quotes and special characters for PowerShell strings.
  static String escapePowerShellString(String input) {
    return input.replaceAll('`', '``').replaceAll('"', '`"').replaceAll(r'$', r'`$');
  }

  /// Builds atomic PowerShell command setting both IPv4 and IPv6 addresses.
  static String buildSetDnsCommand(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  ) {
    final safeName = escapePowerShellString(adapterName);
    final allIps = [...ipv4, ...ipv6];
    final validIpRegex = RegExp(r'^[0-9a-fA-F:.]+$');

    for (final ip in allIps) {
      final trimmed = ip.trim();
      if (!validIpRegex.hasMatch(trimmed) ||
          InternetAddress.tryParse(trimmed) == null) {
        throw ArgumentError('Invalid IP address format: $ip');
      }
    }

    final joined = allIps.map((ip) => '"${ip.trim()}"').join(',');
    return 'Set-DnsClientServerAddress -InterfaceAlias "$safeName" '
        '-ServerAddresses @($joined)';
  }

  /// Builds PowerShell command to reset DNS to DHCP.
  static String buildResetDnsCommand(String adapterName) {
    final safeName = escapePowerShellString(adapterName);
    return 'Set-DnsClientServerAddress -InterfaceAlias "$safeName" '
        '-ResetServerAddresses';
  }

  @override
  Future<bool> isAdministrator() async {
    if (!Platform.isWindows) return false;
    try {
      const script = r'([Security.Principal.WindowsPrincipal]'
          r'[Security.Principal.WindowsIdentity]::GetCurrent())'
          r'.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
      return result.stdout.toString().trim().toLowerCase() == 'true';
    } catch (e) {
      appLogger.warning('WindowsNetworkService', 'Admin check failed: $e');
      return false;
    }
  }

  @override
  Future<List<NetworkAdapter>> getAdapters() async {
    if (!Platform.isWindows) return [];
    try {
      // Query active network interfaces with details
      const script = r'''
Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    $alias = $_.Name
    $desc = $_.InterfaceDescription
    $dns = (Get-DnsClientServerAddress -InterfaceAlias $alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ServerAddresses) -join ","
    $dhcp = (Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue).Dhcp -eq "Enabled"
    $ips = (Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ","
    "$alias;;;$desc;;;$dns;;;$dhcp;;;$ips"
}
''';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);

      if (result.exitCode != 0) {
        throw Exception('PowerShell adapter query failed: ${result.stderr}');
      }

      final lines = result.stdout
          .toString()
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty);

      final adapters = <NetworkAdapter>[];
      for (final line in lines) {
        final parts = line.split(';;;');
        if (parts.length >= 5) {
          final name = parts[0];
          final desc = parts[1];
          final dnsServers = parts[2].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          final isDhcp = parts[3].toLowerCase() == 'true';
          final ipv4List = parts[4].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

          adapters.add(
            NetworkAdapter(
              name: name,
              interfaceDescription: desc,
              isUp: true,
              isDhcp: isDhcp,
              ipv4Addresses: ipv4List,
              ipv6Addresses: const [],
              dnsServers: dnsServers,
            ),
          );
        }
      }
      return adapters;
    } catch (e) {
      appLogger.severe('WindowsNetworkService', 'Failed to get adapters: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getCurrentDns(String adapterName) async {
    if (!Platform.isWindows) return [];
    try {
      final safeName = escapePowerShellString(adapterName);
      final script = 'Get-DnsClientServerAddress -InterfaceAlias "$safeName" | '
          'Select-Object -ExpandProperty ServerAddresses';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ]);
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
      return result.stdout
          .toString()
          .split(RegExp(r'\r?\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      appLogger.warning('WindowsNetworkService', 'Get DNS failed: $e');
      return [];
    }
  }

  @override
  Future<void> setDns(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  ) async {
    final command = buildSetDnsCommand(adapterName, ipv4, ipv6);
    appLogger.info('WindowsNetworkService', 'Applying DNS: $command');

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      command,
    ]);

    if (result.exitCode != 0) {
      final err = result.stderr.toString().isNotEmpty
          ? result.stderr.toString()
          : 'Access denied. Please run as Administrator.';
      appLogger.severe('WindowsNetworkService', 'DNS change failed: $err');
      throw Exception('Failed to set DNS: $err');
    }

    await flushDnsCache();
  }

  @override
  Future<void> restoreDns(String adapterName) async {
    final command = buildResetDnsCommand(adapterName);
    appLogger.info('WindowsNetworkService', 'Restoring DNS: $command');

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      command,
    ]);

    if (result.exitCode != 0) {
      final err = result.stderr.toString().isNotEmpty
          ? result.stderr.toString()
          : 'Access denied. Please run as Administrator.';
      appLogger.severe('WindowsNetworkService', 'DNS restore failed: $err');
      throw Exception('Failed to restore DNS: $err');
    }

    await flushDnsCache();
  }

  @override
  Future<void> flushDnsCache() async {
    try {
      await Process.run('ipconfig', ['/flushdns']);
      await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Clear-DnsClientCache',
      ]);
      appLogger.info('WindowsNetworkService', 'DNS Cache successfully flushed');
    } catch (e) {
      appLogger.warning('WindowsNetworkService', 'Flush cache warning: $e');
    }
  }

  @override
  Future<int?> pingHost(
    String host, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        53,
        timeout: timeout,
      );
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return null;
    }
  }
}
