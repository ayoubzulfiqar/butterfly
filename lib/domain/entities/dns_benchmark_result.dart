enum BenchmarkStatus {
  reachable,
  blocked,
  error,
  failed,
}

class DnsBenchmarkResult {
  final String providerKey;
  final String providerName;
  final String targetKey;
  final BenchmarkStatus status;
  final int latencyMs;
  final String? resolvedIp;
  final String? message;
  final int? httpStatusCode;

  const DnsBenchmarkResult({
    required this.providerKey,
    required this.providerName,
    required this.targetKey,
    required this.status,
    required this.latencyMs,
    this.resolvedIp,
    this.message,
    this.httpStatusCode,
  });

  bool get isSuccessful => status == BenchmarkStatus.reachable;
  bool get isBlocked => status == BenchmarkStatus.blocked;
}
