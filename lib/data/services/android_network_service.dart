import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/utils/logger.dart';
import '../../domain/entities/network_adapter.dart';
import '../../domain/services/i_network_service.dart';

/// Android implementation of [INetworkService] utilizing Android's VpnService
/// via platform method channels for system-wide secure DNS routing.
class AndroidNetworkService implements INetworkService {
  final MethodChannel channel;

  AndroidNetworkService({MethodChannel? channel})
      : channel = channel ?? const MethodChannel('butterfly/vpn');

  @override
  Future<bool> isAdministrator() async => true;

  @override
  Future<List<NetworkAdapter>> getAdapters() async {
    try {
      final transport =
          await channel.invokeMethod<String>('getNetworkTransport') ?? 'Wi-Fi';
      final status =
          await channel.invokeMapMethod<String, dynamic>('getVpnStatus');
      final rawDns = status?['dnsServers'];
      final dnsServers =
          (rawDns as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final isRunning = status?['isRunning'] as bool? ?? false;

      return [
        NetworkAdapter(
          name: transport,
          interfaceDescription: 'Android $transport Network',
          isUp: true,
          isDhcp: !isRunning || dnsServers.isEmpty,
          ipv4Addresses: const [],
          ipv6Addresses: const [],
          dnsServers: dnsServers,
        ),
      ];
    } catch (e) {
      appLogger.warning('AndroidNetworkService', 'Failed to query network adapters: $e');
      return const [
        NetworkAdapter(
          name: 'Wi-Fi',
          interfaceDescription: 'Android Wi-Fi Network',
          isUp: true,
          isDhcp: true,
          ipv4Addresses: [],
          ipv6Addresses: [],
          dnsServers: [],
        ),
      ];
    }
  }

  @override
  Future<List<String>> getCurrentDns(String adapterName) async {
    try {
      final status =
          await channel.invokeMapMethod<String, dynamic>('getVpnStatus');
      final rawDns = status?['dnsServers'];
      return (rawDns as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    } catch (e) {
      appLogger.warning('AndroidNetworkService', 'Failed to get current DNS: $e');
      return [];
    }
  }

  @override
  Future<void> setDns(
    String adapterName,
    List<String> ipv4,
    List<String> ipv6,
  ) async {
    final primary = ipv4.isNotEmpty ? ipv4.first : '1.1.1.1';
    final secondary = ipv4.length > 1 ? ipv4[1] : null;

    try {
      await channel.invokeMethod<bool>('startVpn', {
        'primary': primary,
        'secondary': secondary,
      });
      appLogger.info(
        'AndroidNetworkService',
        'VPN DNS service initiated with primary: $primary, secondary: $secondary',
      );
    } catch (e) {
      appLogger.severe('AndroidNetworkService', 'Failed to start Android VPN DNS: $e');
      rethrow;
    }
  }

  @override
  Future<void> restoreDns(String adapterName) async {
    try {
      await channel.invokeMethod<bool>('stopVpn');
      appLogger.info('AndroidNetworkService', 'VPN DNS service stopped; DHCP restored');
    } catch (e) {
      appLogger.severe('AndroidNetworkService', 'Failed to stop Android VPN DNS: $e');
      rethrow;
    }
  }

  @override
  Future<void> flushDnsCache() async {
    // Reconfiguring the virtual TUN interface naturally refreshes Android DNS routes.
    return Future.value();
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
