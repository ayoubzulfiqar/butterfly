class BenchmarkTarget {
  final String key;
  final String label;
  final String url;

  const BenchmarkTarget({
    required this.key,
    required this.label,
    required this.url,
  });

  String get hostname {
    final normalized = url.contains('://') ? url : 'https://$url';
    try {
      final uri = Uri.parse(normalized);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkTarget &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
