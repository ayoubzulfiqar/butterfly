import 'dart:io';
import '../../domain/services/dpi_engine.dart';

/// Legacy GoodbyeDPI engine for Windows.
class GoodbyeDpiEngine implements DpiEngine {
  Process? _process;

  @override
  String get id => 'goodbyedpi';

  @override
  String get name => 'GoodbyeDPI (Legacy Windows)';

  @override
  String get executableName => 'goodbyedpi.exe';

  @override
  Future<bool> isAvailable() async {
    final file = File(executableName);
    if (file.existsSync()) return true;
    final inBin = File('bin/goodbyedpi.exe');
    return inBin.existsSync();
  }

  @override
  List<String> buildArgs(DpiEngineConfig config) {
    if (config.customArgs.isNotEmpty) {
      return List<String>.from(config.customArgs);
    }
    // Default standard mode
    return ['-1', '--fake-gen=1'];
  }

  @override
  Future<Process> start(DpiEngineConfig config) async {
    final args = buildArgs(config);
    final process = await Process.start(executableName, args);
    _process = process;
    return process;
  }

  @override
  Future<void> stop() async {
    if (_process != null) {
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          _process?.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _process = null;
    }
  }
}
