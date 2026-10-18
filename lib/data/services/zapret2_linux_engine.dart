import 'dart:io';
import '../../domain/entities/zapret2_strategy.dart';
import '../../domain/services/dpi_engine.dart';

/// Linux DPI bypass engine powered by zapret2's nfqws2 and nftables.
class Zapret2LinuxEngine implements DpiEngine {
  Process? _process;

  @override
  String get id => 'zapret2';

  @override
  String get name => 'zapret2 (Linux NFQUEUE)';

  @override
  String get executableName => 'nfqws2';

  @override
  Future<bool> isAvailable() async {
    // Checks for nfqws2 in standard paths or PATH
    final result = await Process.run('which', ['nfqws2']).catchError((_) => ProcessResult(0, 1, '', ''));
    if (result.exitCode == 0) return true;
    final file = File('/usr/local/bin/nfqws2');
    return file.existsSync();
  }

  @override
  List<String> buildArgs(DpiEngineConfig config, {int queueNum = 510, int fwmark = 0x10000}) {
    final args = <String>[
      '--qnum=$queueNum',
      '--fwmark=0x${fwmark.toRadixString(16)}',
      '--user=daemon',
      '--filter-tcp=80,443',
    ];

    if (config.strategy.profile == Zapret2Profile.custom && config.customArgs.isNotEmpty) {
      args.addAll(config.customArgs);
    } else {
      args.addAll(config.strategy.tcpArgs);
      if (config.enableQuic && config.strategy.quicArgs.isNotEmpty) {
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

  /// Generates the nftables rules configuration to direct traffic into NFQUEUE.
  String buildNftablesScript({int queueNum = 510, int fwmark = 0x10000}) {
    final hexFwmark = '0x${fwmark.toRadixString(16)}';
    return '''
table inet butterfly_dpi {
  chain post {
    type filter hook postrouting priority 99; policy accept;
    meta mark & $hexFwmark != 0 ct mark set ct mark | $hexFwmark accept
    oifname "lo" accept
    meta l4proto tcp tcp dport { 80, 443 } ct original packets 1-20 queue flags bypass to $queueNum
    meta l4proto udp udp dport 443 ct original packets 1-20 queue flags bypass to $queueNum
  }
  chain pre {
    type filter hook prerouting priority -99; policy accept;
  }
}
''';
  }

  @override
  Future<Process> start(DpiEngineConfig config) async {
    final args = buildArgs(config);
    // Spawns with elevated rights if required
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
