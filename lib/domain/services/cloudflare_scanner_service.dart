/// Represents a benchmarked Cloudflare edge IP address.
class CloudflareCleanIp {
  final String ip;
  final int latencyMs;
  final double packetLoss;
  final bool isClean;

  const CloudflareCleanIp({
    required this.ip,
    required this.latencyMs,
    required this.packetLoss,
    required this.isClean,
  });

  @override
  String toString() => '$ip ($latencyMs ms)';
}

/// Abstract contract for the Cloudflare clean IP diagnostic scanner.
abstract class ICloudflareScannerService {
  /// Stream of scan progress from 0.0 to 1.0.
  Stream<double> get progressStream;

  /// Performs reachability and latency probe across Cloudflare Anycast IPs.
  Future<List<CloudflareCleanIp>> scanCleanIps({
    List<String>? targetIps,
    int limit = 10,
    Duration timeout = const Duration(seconds: 2),
  });
}
