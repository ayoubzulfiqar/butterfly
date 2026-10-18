import 'dart:io';
import '../entities/zapret2_strategy.dart';

/// Configuration options for launching a DPI engine.
class DpiEngineConfig {
  final Zapret2Strategy strategy;
  final bool enableQuic;
  final List<String> customArgs;

  const DpiEngineConfig({
    required this.strategy,
    this.enableQuic = true,
    this.customArgs = const [],
  });
}

/// Abstract contract for a native DPI bypass engine (zapret2, goodbyedpi).
abstract class DpiEngine {
  /// Unique identifier of the engine (e.g. 'zapret2', 'goodbyedpi').
  String get id;

  /// User-friendly display name.
  String get name;

  /// Underlying executable name (e.g. 'winws2.exe', 'nfqws2', 'goodbyedpi.exe').
  String get executableName;

  /// Verifies whether the engine's executable is installed/available.
  Future<bool> isAvailable();

  /// Builds the exact command-line arguments for the given [config].
  List<String> buildArgs(DpiEngineConfig config);

  /// Spawns the engine process with the given [config].
  Future<Process> start(DpiEngineConfig config);

  /// Stops any running engine instance and cleans up platform hooks.
  Future<void> stop();
}
