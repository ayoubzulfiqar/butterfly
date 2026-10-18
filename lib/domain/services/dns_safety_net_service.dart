import '../entities/network_adapter.dart';
import 'i_network_service.dart';

/// Represents a persistent snapshot of an adapter's pre-mutation DNS configuration.
class DnsSnapshot {
  final String interfaceName;
  final bool isDhcp;
  final List<String> dnsServers;
  final DateTime timestamp;

  const DnsSnapshot({
    required this.interfaceName,
    required this.isDhcp,
    required this.dnsServers,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'interfaceName': interfaceName,
        'isDhcp': isDhcp,
        'dnsServers': dnsServers,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DnsSnapshot.fromJson(Map<String, dynamic> json) {
    return DnsSnapshot(
      interfaceName: json['interfaceName'] as String? ?? '',
      isDhcp: json['isDhcp'] as bool? ?? true,
      dnsServers: (json['dnsServers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Abstract contract for the bulletproof DNS safety net service.
abstract class IDnsSafetyNetService {
  /// Snapshots the current DNS configuration of [adapter] to persistent storage.
  Future<void> snapshotCurrentDns(NetworkAdapter adapter);

  /// Reports whether an un-restored snapshot file exists on disk.
  Future<bool> hasPendingRestore();

  /// Deserializes the pending snapshot, returning null if missing or malformed.
  Future<DnsSnapshot?> readSnapshot();

  /// Reapplies original DNS settings using [networkService] and deletes the snapshot file.
  Future<bool> restoreOriginalDns(INetworkService networkService);

  /// Removes any existing snapshot file.
  Future<void> clearSnapshot();
}
