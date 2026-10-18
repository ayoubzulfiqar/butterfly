import '../entities/dpi_bypass_mode.dart';
import '../entities/zapret2_strategy.dart';

/// Contract for Deep Packet Inspection (DPI) bypass execution service.
abstract class IDpiService {
  /// Whether the DPI bypass process is currently running.
  bool get isRunning;

  /// Active engine ID (e.g. 'zapret2', 'goodbyedpi').
  String get activeEngine;

  /// Active strategy when running zapret2.
  Zapret2Strategy? get activeStrategy;

  /// Stream of running state transitions.
  Stream<bool> get runningStateStream;

  /// Stream of stdout/stderr log output from the background process.
  Stream<String> get processLogsStream;

  /// Verifies whether the DPI executable is available on the system.
  Future<bool> isExecutableAvailable();

  /// Starts DPI bypass in the specified legacy [mode] (GoodbyeDPI).
  Future<void> start(DpiBypassMode mode);

  /// Starts DPI bypass using zapret2 with the specified [strategy].
  Future<void> startZapret2(
    Zapret2Strategy strategy, {
    bool enableQuic = true,
    List<String> customArgs = const [],
  });

  /// Stops the running DPI bypass process cleanly.
  Future<void> stop();

  /// Cleans up subscriptions and kills any orphaned processes.
  void dispose();
}
