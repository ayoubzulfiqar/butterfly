import 'dart:typed_data';

/// Method used to split the TLS ClientHello packet.
enum TlsFragMethod {
  /// Splits the TCP payload directly across the SNI extension bytes into discrete segments.
  tcp,

  /// Re-wraps the ClientHello into multiple TLS record-layer frames within a single payload.
  record,

  /// Combines TLS record fragmentation and TCP segmentation.
  both,
}

/// Represents the byte offset of the SNI hostname inside a ClientHello packet.
class SniRange {
  final int start;
  final int end;
  final bool found;

  const SniRange(this.start, this.end, this.found);

  static const notFound = SniRange(0, 0, false);
}

/// Contract for the driverless TLS ClientHello fragmentation service.
abstract class ITlsFragmenterService {
  /// Whether the local proxy server is currently active.
  bool get isRunning;

  /// Port on which the local proxy is listening (default: 8085).
  int get port;

  /// Active fragmentation method.
  TlsFragMethod get method;

  /// Starts the local fragmentation proxy.
  Future<void> start({
    int port = 8085,
    TlsFragMethod method = TlsFragMethod.both,
    int chunks = 2,
  });

  /// Stops the local proxy server.
  Future<void> stop();

  /// Locates the SNI hostname range inside a raw [packet].
  SniRange sniRange(Uint8List packet);

  /// Splits a TLS [packet] using the specified [method] and [chunks].
  List<Uint8List> split(Uint8List packet, TlsFragMethod method, {int chunks = 2});
}
