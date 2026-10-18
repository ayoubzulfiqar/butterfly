import '../entities/dpi_bypass_mode.dart';

/// Contract for Deep Packet Inspection (DPI) bypass execution service.
abstract class IDpiService {
  /// Whether the DPI bypass process is currently running.
  bool get isRunning;

  /// Stream of running state transitions.
  Stream<bool> get runningStateStream;

  /// Stream of stdout/stderr log output from the background process.
  Stream<String> get processLogsStream;

  /// Verifies whether the GoodbyeDPI executable is available on the system.
  Future<bool> isExecutableAvailable();

  /// Starts DPI bypass in the specified [mode].
  Future<void> start(DpiBypassMode mode);

  /// Stops the running DPI bypass process cleanly.
  Future<void> stop();

  /// Cleans up subscriptions and kills any orphaned processes.
  void dispose();
}
