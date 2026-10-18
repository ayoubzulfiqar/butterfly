import 'dart:io';
import 'dart:typed_data';
import '../../core/utils/logger.dart';
import '../../domain/services/tls_fragmenter.dart';

/// Pure Dart implementation of driverless TLS ClientHello fragmentation.
class TlsFragmenterServiceImpl implements ITlsFragmenterService {
  ServerSocket? _server;
  bool _isRunning = false;
  int _port = 8085;
  TlsFragMethod _method = TlsFragMethod.both;
  int _chunks = 2;

  @override
  bool get isRunning => _isRunning;

  @override
  int get port => _port;

  @override
  TlsFragMethod get method => _method;

  @override
  SniRange sniRange(Uint8List packet) {
    if (packet.length < 44) return SniRange.notFound;

    // Check TLS record header: 0x16 (Handshake) and 0x03 (TLS major)
    if (packet[0] != 0x16 || packet[1] != 0x03) {
      return SniRange.notFound;
    }

    // Check Handshake Type: 0x01 (ClientHello)
    if (packet[5] != 0x01) {
      return SniRange.notFound;
    }

    try {
      var offset = 9; // Skip record header (5) + handshake type (1) + length (3)
      offset += 2; // Client Version (2)
      offset += 32; // Random (32)

      if (offset >= packet.length) return SniRange.notFound;
      final sessionIdLen = packet[offset];
      offset += 1 + sessionIdLen;

      if (offset + 2 > packet.length) return SniRange.notFound;
      final cipherSuitesLen = (packet[offset] << 8) | packet[offset + 1];
      offset += 2 + cipherSuitesLen;

      if (offset + 1 > packet.length) return SniRange.notFound;
      final compressionMethodsLen = packet[offset];
      offset += 1 + compressionMethodsLen;

      if (offset + 2 > packet.length) return SniRange.notFound;
      final extensionsLen = (packet[offset] << 8) | packet[offset + 1];
      offset += 2;

      final extensionsEnd = offset + extensionsLen;
      if (extensionsEnd > packet.length) return SniRange.notFound;

      while (offset + 4 <= extensionsEnd) {
        final extType = (packet[offset] << 8) | packet[offset + 1];
        final extLen = (packet[offset + 2] << 8) | packet[offset + 3];
        offset += 4;

        if (extType == 0x0000) {
          // server_name extension
          if (offset + 2 > extensionsEnd) return SniRange.notFound;
          final serverNameListLen = (packet[offset] << 8) | packet[offset + 1];
          var p = offset + 2;
          final listEnd = p + serverNameListLen;

          while (p + 3 <= listEnd && p + 3 <= packet.length) {
            final nameType = packet[p];
            final nameLen = (packet[p + 1] << 8) | packet[p + 2];
            p += 3;

            if (nameType == 0 && p + nameLen <= packet.length) {
              // 0 = host_name
              return SniRange(p, p + nameLen, true);
            }
            p += nameLen;
          }
        }
        offset += extLen;
      }
    } catch (_) {
      return SniRange.notFound;
    }

    return SniRange.notFound;
  }

  @override
  List<Uint8List> split(Uint8List packet, TlsFragMethod method, {int chunks = 2}) {
    final range = sniRange(packet);
    if (!range.found || chunks < 1) {
      return [packet];
    }

    switch (method) {
      case TlsFragMethod.tcp:
        return _splitTcp(packet, range.start, range.end, chunks);
      case TlsFragMethod.record:
      case TlsFragMethod.both:
        return _splitTcp(packet, range.start, range.end, chunks);
    }
  }

  List<Uint8List> _splitTcp(Uint8List packet, int start, int end, int chunks) {
    final out = <Uint8List>[];
    out.add(Uint8List.fromList(packet.sublist(0, start)));

    final hostLen = end - start;
    final chunkSize = hostLen ~/ chunks;

    for (var i = 0; i < chunks; i++) {
      final lo = start + (i * chunkSize);
      final hi = (i == chunks - 1) ? end : lo + chunkSize;
      out.add(Uint8List.fromList(packet.sublist(lo, hi)));
    }

    if (end < packet.length) {
      out.add(Uint8List.fromList(packet.sublist(end)));
    }

    return out;
  }

  @override
  Future<void> start({
    int port = 8085,
    TlsFragMethod method = TlsFragMethod.both,
    int chunks = 2,
  }) async {
    if (_isRunning) await stop();

    _port = port;
    _method = method;
    _chunks = chunks;

    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _isRunning = true;
      appLogger.info('TlsFragmenter', 'Started local fragmentation proxy on 127.0.0.1:$_port');

      _server!.listen((client) {
        _handleClient(client);
      });
    } catch (e) {
      _isRunning = false;
      appLogger.severe('TlsFragmenter', 'Failed to start proxy: $e');
      rethrow;
    }
  }

  void _handleClient(Socket client) {
    // Handle standard HTTP CONNECT proxy handshake
    var handshakeHandled = false;
    Socket? upstream;

    client.listen(
      (data) async {
        if (!handshakeHandled) {
          final request = String.fromCharCodes(data);
          if (request.startsWith('CONNECT ')) {
            handshakeHandled = true;
            final target = request.split(' ')[1];
            final parts = target.split(':');
            final host = parts[0];
            final targetPort = parts.length > 1 ? int.tryParse(parts[1]) ?? 443 : 443;

            try {
              upstream = await Socket.connect(host, targetPort);
              client.write('HTTP/1.1 200 Connection Established\r\n\r\n');

              upstream!.listen(
                (upData) => client.add(upData),
                onError: (_) => client.destroy(),
                onDone: () => client.destroy(),
              );
            } catch (e) {
              client.destroy();
            }
            return;
          }
        }

        // Forward data with fragmentation applied if initial packet is TLS ClientHello
        if (upstream != null) {
          final fragments = split(data, _method, chunks: _chunks);
          for (final f in fragments) {
            upstream!.add(f);
            await upstream!.flush();
          }
        }
      },
      onError: (_) {
        upstream?.destroy();
        client.destroy();
      },
      onDone: () {
        upstream?.destroy();
      },
    );
  }

  @override
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
    appLogger.info('TlsFragmenter', 'Stopped local fragmentation proxy');
  }
}
