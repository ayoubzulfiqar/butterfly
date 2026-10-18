import 'package:butterfly/domain/entities/benchmark_target.dart';
import 'package:butterfly/domain/entities/dns_benchmark_result.dart';
import 'package:butterfly/domain/entities/dns_provider.dart';

abstract class IDnsBenchmarkService {
  List<BenchmarkTarget> get defaultTargets;

  Future<DnsBenchmarkResult> benchmarkServer(
    DnsProvider provider,
    BenchmarkTarget target, {
    Duration timeout = const Duration(seconds: 6),
  });

  Future<List<DnsBenchmarkResult>> benchmarkAllServers(
    List<DnsProvider> providers,
    BenchmarkTarget target, {
    int concurrency = 6,
    Duration timeout = const Duration(seconds: 6),
  });
}
