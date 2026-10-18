import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/services/tls_fragmenter.dart';
import 'package:butterfly/data/services/tls_fragmenter_service_impl.dart';

void main() {
  group('TLS ClientHello Parser and Splitter Tests', () {
    late TlsFragmenterServiceImpl fragmenter;

    setUp(() {
      fragmenter = TlsFragmenterServiceImpl();
    });

    // Helper to generate a realistic synthetic TLS ClientHello with SNI "example.com"
    Uint8List buildSyntheticClientHello(String hostname) {
      final hostBytes = hostname.codeUnits;
      final serverNameLen = hostBytes.length;
      final serverNameListLen = serverNameLen + 3; // 1 byte type + 2 bytes len
      final extDataLen = serverNameListLen + 2;

      final extensions = <int>[
        0x00, 0x00, // ext type 0 (server_name)
        (extDataLen >> 8) & 0xff, extDataLen & 0xff,
        (serverNameListLen >> 8) & 0xff, serverNameListLen & 0xff,
        0x00, // host_name type
        (serverNameLen >> 8) & 0xff, serverNameLen & 0xff,
        ...hostBytes,
        0x00, 0x0b, // ext type 11 (ec_point_formats)
        0x00, 0x02, // ext len 2
        0x01, 0x00, // formats
      ];

      final clientHelloBody = <int>[
        0x01, // ClientHello
        0x00, 0x00, 0x00, // length placeholder (3 bytes)
        0x03, 0x03, // TLS 1.2 client version
        ...List.filled(32, 0xAA), // Random (32 bytes)
        0x00, // Session ID length (0)
        0x00, 0x02, 0x00, 0x2f, // Cipher suites (1 suite)
        0x01, 0x00, // Compression (1 method: null)
        (extensions.length >> 8) & 0xff, extensions.length & 0xff,
        ...extensions,
      ];

      final bodyLen = clientHelloBody.length - 4;
      clientHelloBody[1] = (bodyLen >> 16) & 0xff;
      clientHelloBody[2] = (bodyLen >> 8) & 0xff;
      clientHelloBody[3] = bodyLen & 0xff;

      final record = <int>[
        0x16, // Handshake record
        0x03, 0x01, // Record layer TLS 1.0
        (clientHelloBody.length >> 8) & 0xff, clientHelloBody.length & 0xff,
        ...clientHelloBody,
      ];

      return Uint8List.fromList(record);
    }

    test('sniRange correctly detects SNI offsets for example.com', () {
      final packet = buildSyntheticClientHello('example.com');
      final range = fragmenter.sniRange(packet);

      expect(range.found, isTrue);
      expect(range.start, isPositive);
      expect(range.end, greaterThan(range.start));

      final extracted = String.fromCharCodes(packet.sublist(range.start, range.end));
      expect(extracted, equals('example.com'));
    });

    test('sniRange returns found=false for non-TLS packets', () {
      final plainHttp = Uint8List.fromList('GET / HTTP/1.1\r\nHost: example.com\r\n\r\n'.codeUnits);
      final range = fragmenter.sniRange(plainHttp);

      expect(range.found, isFalse);
    });

    test('split with MethodTCP splits payload inside SNI into chunks', () {
      final packet = buildSyntheticClientHello('speed.cloudflare.com');
      final chunks = fragmenter.split(packet, TlsFragMethod.tcp, chunks: 2);

      // MethodTCP splits into: pre-SNI + chunk1 + chunk2 + post-SNI
      expect(chunks.length, equals(4));

      // Assembling chunks must recreate the original packet byte-for-byte
      final reconstructed = <int>[];
      for (final c in chunks) {
        reconstructed.addAll(c);
      }
      expect(Uint8List.fromList(reconstructed), equals(packet));
    });

    test('split passes non-TLS packets whole without mutation', () {
      final plainHttp = Uint8List.fromList('POST /api HTTP/1.1\r\n\r\n'.codeUnits);
      final chunks = fragmenter.split(plainHttp, TlsFragMethod.tcp, chunks: 2);

      expect(chunks.length, equals(1));
      expect(chunks.first, equals(plainHttp));
    });

    test('split with MethodRecord creates multiple valid TLS 0x16 records', () {
      final packet = buildSyntheticClientHello('example.org');
      final records = fragmenter.split(packet, TlsFragMethod.record, chunks: 2);

      expect(records.length, greaterThan(1));
      for (final rec in records) {
        expect(rec[0], equals(0x16)); // Handshake
        expect(rec.length, greaterThan(5)); // Record header + payload
        final payloadLen = (rec[3] << 8) | rec[4];
        expect(rec.length - 5, equals(payloadLen));
      }
    });
  });
}
