import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../domain/entities/benchmark_target.dart';
import '../../domain/entities/dns_benchmark_result.dart';
import '../../domain/entities/dns_provider.dart';
import '../../domain/services/i_dns_benchmark_service.dart';

class DnsBenchmarkServiceImpl implements IDnsBenchmarkService {
  @override
  List<BenchmarkTarget> get defaultTargets => const [
        BenchmarkTarget(
          key: 'chatgpt',
          label: 'ChatGPT (OpenAI)',
          url: 'https://chatgpt.com',
        ),
        BenchmarkTarget(
          key: 'claude',
          label: 'Claude (Anthropic)',
          url: 'https://claude.ai',
        ),
        BenchmarkTarget(
          key: 'gemini',
          label: 'Google Gemini',
          url: 'https://gemini.google.com',
        ),
        BenchmarkTarget(
          key: 'google',
          label: 'Google Search',
          url: 'https://google.com',
        ),
        BenchmarkTarget(
          key: 'youtube',
          label: 'YouTube',
          url: 'https://youtube.com',
        ),
        BenchmarkTarget(
          key: 'github',
          label: 'GitHub',
          url: 'https://github.com',
        ),
        BenchmarkTarget(
          key: 'twitter',
          label: 'X (Twitter)',
          url: 'https://x.com',
        ),
        BenchmarkTarget(
          key: 'discord',
          label: 'Discord',
          url: 'https://discord.com',
        ),
        BenchmarkTarget(
          key: 'reddit',
          label: 'Reddit',
          url: 'https://reddit.com',
        ),
        BenchmarkTarget(
          key: 'wikipedia',
          label: 'Wikipedia',
          url: 'https://wikipedia.org',
        ),
      ];

  static Uint8List buildDnsQueryPacket(String hostname, int txId) {
    final buffer = BytesBuilder();

    // 12-byte DNS Header
    buffer.addByte((txId >> 8) & 0xFF);
    buffer.addByte(txId & 0xFF);
    buffer.addByte(0x01); // Flags: standard query, recursion desired
    buffer.addByte(0x00);
    buffer.addByte(0x00); // QDCOUNT = 1
    buffer.addByte(0x01);
    buffer.addByte(0x00); // ANCOUNT = 0
    buffer.addByte(0x00);
    buffer.addByte(0x00); // NSCOUNT = 0
    buffer.addByte(0x00);
    buffer.addByte(0x00); // ARCOUNT = 0
    buffer.addByte(0x00);

    // QNAME
    final labels = hostname.split('.');
    for (final label in labels) {
      if (label.isEmpty) continue;
      buffer.addByte(label.length);
      buffer.add(label.codeUnits);
    }
    buffer.addByte(0x00); // End of QNAME

    // QTYPE = 1 (A), QCLASS = 1 (IN)
    buffer.addByte(0x00);
    buffer.addByte(0x01);
    buffer.addByte(0x00);
    buffer.addByte(0x01);

    return buffer.toBytes();
  }

  static String? parseIpFromDnsResponse(Uint8List bytes) {
    if (bytes.length < 12) return null;

    final ancount = (bytes[6] << 8) | bytes[7];
    if (ancount == 0) return null;

    int offset = 12;

    // Skip Question Section
    while (offset < bytes.length && bytes[offset] != 0) {
      if ((bytes[offset] & 0xC0) == 0xC0) {
        offset += 2;
        break;
      }
      offset += bytes[offset] + 1;
    }
    if (offset < bytes.length && bytes[offset] == 0) {
      offset += 5; // null byte + 2 byte QTYPE + 2 byte QCLASS
    }

    // Parse Answers
    for (int i = 0; i < ancount && offset < bytes.length; i++) {
      if (offset + 12 > bytes.length) break;

      // Skip Name (pointer or labels)
      if ((bytes[offset] & 0xC0) == 0xC0) {
        offset += 2;
      } else {
        while (offset < bytes.length && bytes[offset] != 0) {
          offset += bytes[offset] + 1;
        }
        offset++;
      }

      if (offset + 10 > bytes.length) break;

      final type = (bytes[offset] << 8) | bytes[offset + 1];
      final rdLength = (bytes[offset + 8] << 8) | bytes[offset + 9];
      offset += 10;

      if (type == 1 && rdLength == 4 && offset + 4 <= bytes.length) {
        // IPv4 Address
        final ip = '${bytes[offset]}.${bytes[offset + 1]}.${bytes[offset + 2]}.${bytes[offset + 3]}';
        return ip;
      }

      offset += rdLength;
    }

    return null;
  }

  static BenchmarkStatus classifyStatus(int? statusCode) {
    if (statusCode == null) return BenchmarkStatus.failed;
    if (statusCode == 403) return BenchmarkStatus.blocked;
    if (statusCode >= 200 && statusCode < 400) return BenchmarkStatus.reachable;
    if (statusCode >= 500 || statusCode == 0) return BenchmarkStatus.error;
    return BenchmarkStatus.failed;
  }

  Future<String?> _resolveHostWithServer(
    String serverIp,
    String hostname,
    Duration timeout,
  ) async {
    final completer = Completer<String?>();
    RawDatagramSocket? socket;
    Timer? timer;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final txId = Random().nextInt(0xFFFF);
      final query = buildDnsQueryPacket(hostname, txId);

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null && datagram.data.length >= 12) {
            final responseTxId = (datagram.data[0] << 8) | datagram.data[1];
            if (responseTxId == txId) {
              final parsed = parseIpFromDnsResponse(datagram.data);
              if (!completer.isCompleted) {
                completer.complete(parsed);
              }
            }
          }
        }
      });

      socket.send(query, InternetAddress(serverIp), 53);

      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      final result = await completer.future;
      return result;
    } catch (_) {
      return null;
    } finally {
      timer?.cancel();
      socket?.close();
    }
  }

  Future<int?> _probeHttpReachability(
    String ip,
    String hostname,
    Duration timeout,
  ) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = timeout;
      client.badCertificateCallback = (cert, host, port) => true;

      // Direct TCP connection to resolved server IP while preserving
      // hostname in the TLS ClientHello SNI for accurate censorship detection.
      client.connectionFactory = (uri, host, port) {
        return Socket.startConnect(ip, port ?? 443);
      };

      final request = await client.getUrl(Uri.parse('https://$hostname/'));
      request.headers.set(HttpHeaders.connectionHeader, 'close');

      final response = await request.close().timeout(timeout);
      return response.statusCode;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  @override
  Future<DnsBenchmarkResult> benchmarkServer(
    DnsProvider provider,
    BenchmarkTarget target, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final ips = provider.ipv4.where((ip) => ip.trim().isNotEmpty && ip != '0.0.0.0').toList();
    if (ips.isEmpty) {
      return DnsBenchmarkResult(
        providerKey: provider.id,
        providerName: provider.name,
        targetKey: target.key,
        status: BenchmarkStatus.failed,
        latencyMs: -1,
        message: 'No DNS address configured',
      );
    }

    final sw = Stopwatch()..start();
    final primaryIp = ips.first;
    final hostname = target.hostname;

    try {
      final resolvedIp = await _resolveHostWithServer(
        primaryIp,
        hostname,
        Duration(milliseconds: min(timeout.inMilliseconds, 3000)),
      );

      final dnsDuration = sw.elapsedMilliseconds;

      if (resolvedIp == null) {
        return DnsBenchmarkResult(
          providerKey: provider.id,
          providerName: provider.name,
          targetKey: target.key,
          status: BenchmarkStatus.failed,
          latencyMs: dnsDuration,
          message: 'DNS lookup failed / timed out',
        );
      }

      final statusCode = await _probeHttpReachability(
        resolvedIp,
        hostname,
        Duration(milliseconds: min(timeout.inMilliseconds, 3000)),
      );

      final totalLatency = sw.elapsedMilliseconds;
      final status = classifyStatus(statusCode);

      String msg = 'Reachable';
      if (status == BenchmarkStatus.blocked) {
        msg = 'Blocked (403 Forbidden / Censored)';
      } else if (status == BenchmarkStatus.error) {
        msg = 'Server Error ($statusCode)';
      } else if (status == BenchmarkStatus.failed) {
        msg = 'Transport Failed';
      }

      return DnsBenchmarkResult(
        providerKey: provider.id,
        providerName: provider.name,
        targetKey: target.key,
        status: status,
        latencyMs: totalLatency,
        resolvedIp: resolvedIp,
        message: msg,
        httpStatusCode: statusCode,
      );
    } catch (e) {
      return DnsBenchmarkResult(
        providerKey: provider.id,
        providerName: provider.name,
        targetKey: target.key,
        status: BenchmarkStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        message: 'Benchmark failed: $e',
      );
    }
  }

  @override
  Future<List<DnsBenchmarkResult>> benchmarkAllServers(
    List<DnsProvider> providers,
    BenchmarkTarget target, {
    int concurrency = 6,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final List<DnsBenchmarkResult> results = [];
    final queue = List<DnsProvider>.from(providers);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final provider = queue.removeAt(0);
        final result = await benchmarkServer(provider, target, timeout: timeout);
        results.add(result);
      }
    }

    final workerCount = min(concurrency, max(1, providers.length));
    final workers = List.generate(workerCount, (_) => worker());
    await Future.wait(workers);

    results.sort((a, b) {
      if (a.status == BenchmarkStatus.reachable &&
          b.status != BenchmarkStatus.reachable) {
        return -1;
      }
      if (a.status != BenchmarkStatus.reachable &&
          b.status == BenchmarkStatus.reachable) {
        return 1;
      }
      if (a.latencyMs == -1 && b.latencyMs == -1) {
        return 0;
      }
      if (a.latencyMs == -1) {
        return 1;
      }
      if (b.latencyMs == -1) {
        return -1;
      }
      return a.latencyMs.compareTo(b.latencyMs);
    });

    return results;
  }
}
