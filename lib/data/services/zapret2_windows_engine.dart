import 'dart:io';
import '../../domain/entities/zapret2_strategy.dart';
import '../../domain/services/dpi_engine.dart';

/// Windows DPI bypass engine powered by zapret2's winws2.exe and WinDivert.
class Zapret2WindowsEngine implements DpiEngine {
  Process? _process;

  @override
  String get id => 'zapret2';

  @override
  String get name => 'zapret2 (Windows WinDivert)';

  @override
  String get executableName => 'winws2.exe';

  @override
  Future<bool> isAvailable() async {
    final file = File(executableName);
    if (file.existsSync()) return true;
    final inBin = File('bin/zapret2/winws2.exe');
    return inBin.existsSync();
  }

  @override
  List<String> buildArgs(DpiEngineConfig config) {
    final args = <String>[
      '--wf-tcp-out=80,443',
    ];

    final hasQuic = config.enableQuic && config.strategy.quicArgs.isNotEmpty;
    if (hasQuic) {
      args.add('--wf-udp-out=443');
    }

    args.addAll([
      '--wf-dup-check=1',
      '--filter-tcp=80,443',
    ]);

    if (config.strategy.profile == Zapret2Profile.custom && config.customArgs.isNotEmpty) {
      args.addAll(config.customArgs);
    } else {
      args.addAll(config.strategy.tcpArgs);
      if (hasQuic) {
        args.addAll([
          '--new',
          '--filter-udp=443',
          '--filter-l7=quic',
          ...config.strategy.quicArgs,
        ]);
      }
    }

    return args;
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
