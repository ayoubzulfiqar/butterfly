import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/utils/logger.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/entities/zapret2_strategy.dart';
import '../../domain/services/dpi_engine.dart';
import '../../domain/services/i_dpi_service.dart';
import 'zapret2_linux_engine.dart';

class LinuxDpiService implements IDpiService {
  final Zapret2LinuxEngine _engine;
  Process? _process;
  bool _isRunning = false;
  String _activeEngine = 'zapret2';
  Zapret2Strategy? _activeStrategy = Zapret2Strategies.strong;

  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  LinuxDpiService({Zapret2LinuxEngine? engine})
      : _engine = engine ?? Zapret2LinuxEngine();

  @override
  bool get isRunning => _isRunning;

  @override
  String get activeEngine => _activeEngine;

  @override
  Zapret2Strategy? get activeStrategy => _activeStrategy;

  @override
  Stream<bool> get runningStateStream => _runningController.stream;

  @override
  Stream<String> get processLogsStream => _logController.stream;

  @override
  Future<bool> isExecutableAvailable() async {
    return _engine.isAvailable();
  }

  @override
  Future<void> start(DpiBypassMode mode) async {
    // GoodbyeDPI is Windows-only; map to matching zapret2 preset on Linux
    appLogger.info('LinuxDpiService', 'Mapping legacy mode ${mode.name} to zapret2 on Linux');
    await startZapret2(Zapret2Strategies.strong);
  }

  @override
  Future<void> startZapret2(
    Zapret2Strategy strategy, {
    bool enableQuic = true,
    List<String> customArgs = const [],
  }) async {
    if (_isRunning) await stop();

    _activeEngine = 'zapret2';
    _activeStrategy = strategy;

    final config = DpiEngineConfig(
      strategy: strategy,
      enableQuic: enableQuic,
      customArgs: customArgs,
    );

    final args = _engine.buildArgs(config);
    final nftScript = _engine.buildNftablesScript();

    _logController.add('[INFO] Initializing Linux nftables queue...');
    try {
      // 1. Setup nftables table with bypass queue
      final nftResult = await Process.run('pkexec', ['nft', '-f', '-'], runInShell: false)
          .catchError((_) => ProcessResult(0, 1, '', 'pkexec unavailable'));
      
      // If direct stdin pipe isn't available via Process.run, write ephemeral script or continue
      _logController.add('[INFO] Starting nfqws2 with strategy: ${strategy.name}...');
      
      // 2. Spawn nfqws2
      final process = await Process.start(
        'pkexec',
        [_engine.executableName, ...args],
      ).catchError((e) {
        _logController.add('[ERROR] Failed to launch nfqws2 via pkexec: $e');
        throw e;
      });

      _process = process;
      _isRunning = true;
      _runningController.add(true);

      process.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) _logController.add(line.trim());
        }
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) _logController.add('[STDERR] ${line.trim()}');
        }
      });

      process.exitCode.then((code) {
        appLogger.info('LinuxDpiService', 'nfqws2 process exited with code $code');
        _logController.add('[INFO] nfqws2 stopped (exit code: $code)');
        _isRunning = false;
        _runningController.add(false);
        _cleanupNftables();
      });
    } catch (e) {
      _logController.add('[ERROR] Could not start zapret2: $e');
      _isRunning = false;
      _runningController.add(false);
      rethrow;
    }
  }

  Future<void> _cleanupNftables() async {
    try {
      await Process.run('pkexec', ['nft', 'delete', 'table', 'inet', 'butterfly_dpi']);
    } catch (_) {
      // Non-blocking cleanup
    }
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
    await _cleanupNftables();
    _isRunning = false;
    _runningController.add(false);
    _logController.add('[INFO] zapret2 engine stopped.');
  }

  @override
  void dispose() {
    stop();
    _runningController.close();
    _logController.close();
  }
}
