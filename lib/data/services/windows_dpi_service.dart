import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/entities/zapret2_strategy.dart';
import '../../domain/services/dpi_engine.dart';
import '../../domain/services/i_dpi_service.dart';
import 'zapret2_windows_engine.dart';

/// Service managing the lifecycle of zapret2 (winws2.exe) and GoodbyeDPI on Windows.
class WindowsDpiService with WidgetsBindingObserver implements IDpiService {
  final Zapret2WindowsEngine _zapret2Engine;
  Process? _process;
  String _activeEngine = 'zapret2';
  Zapret2Strategy? _activeStrategy = Zapret2Strategies.strong;
  final _runningStateController = StreamController<bool>.broadcast();
  final _logsController = StreamController<String>.broadcast();

  WindowsDpiService({Zapret2WindowsEngine? zapret2Engine})
      : _zapret2Engine = zapret2Engine ?? Zapret2WindowsEngine() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  bool get isRunning => _process != null;

  @override
  String get activeEngine => _activeEngine;

  @override
  Zapret2Strategy? get activeStrategy => _activeStrategy;

  @override
  Stream<bool> get runningStateStream => _runningStateController.stream;

  @override
  Stream<String> get processLogsStream => _logsController.stream;

  /// Resolves the file path to executable across common locations.
  String? getExecutablePath(String name) {
    final candidatePaths = [
      path.join(path.dirname(Platform.resolvedExecutable), name),
      path.join(Directory.current.path, name),
      path.join(Directory.current.path, 'assets', 'bin', name),
      path.join(Directory.current.path, 'bin', name),
      path.join(Directory.current.path, 'bin', 'zapret2', name),
      path.join(
        path.dirname(Platform.resolvedExecutable),
        'data',
        'flutter_assets',
        'assets',
        'bin',
        name,
      ),
    ];

    for (final p in candidatePaths) {
      if (File(p).existsSync()) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<bool> isExecutableAvailable() async {
    if (!Platform.isWindows) return false;
    return getExecutablePath('winws2.exe') != null || getExecutablePath('goodbyedpi.exe') != null;
  }

  @override
  Future<void> start(DpiBypassMode mode) async {
    // Legacy GoodbyeDPI launcher
    _activeEngine = 'goodbyedpi';
    final exePath = getExecutablePath('goodbyedpi.exe');
    if (exePath == null) {
      // If goodbyedpi is absent, attempt zapret2 equivalent
      appLogger.warning('WindowsDpiService', 'goodbyedpi.exe not found, launching zapret2 fallback');
      await startZapret2(Zapret2Strategies.strong);
      return;
    }
    await _startProcess(exePath, mode.args, 'GoodbyeDPI');
  }

  @override
  Future<void> startZapret2(
    Zapret2Strategy strategy, {
    bool enableQuic = true,
    List<String> customArgs = const [],
  }) async {
    _activeEngine = 'zapret2';
    _activeStrategy = strategy;

    final config = DpiEngineConfig(
      strategy: strategy,
      enableQuic: enableQuic,
      customArgs: customArgs,
    );

    final args = _zapret2Engine.buildArgs(config);
    final exePath = getExecutablePath('winws2.exe') ?? 'winws2.exe';

    await _startProcess(exePath, args, 'zapret2');
  }

  Future<void> _cleanupOrphanWinDivert() async {
    if (!Platform.isWindows) return;
    try {
      final res = await Process.run('sc', ['query', 'WinDivert']);
      if (res.exitCode == 0 && res.stdout.toString().contains('RUNNING')) {
        appLogger.info('WindowsDpiService', 'Stopping orphaned WinDivert driver service');
        await Process.run('sc', ['stop', 'WinDivert']);
      }
    } catch (e) {
      appLogger.warning('WindowsDpiService', 'WinDivert orphan service check: $e');
    }
  }

  Future<void> _startProcess(String exePath, List<String> args, String engineTag) async {
    if (_process != null) {
      appLogger.info('WindowsDpiService', 'DPI process is already running, stopping first');
      await stop();
    }

    await _cleanupOrphanWinDivert();

    try {
      appLogger.info(
        'WindowsDpiService',
        'Launching $engineTag: $exePath ${args.join(' ')}',
      );

      final workingDir = File(exePath).existsSync() ? path.dirname(exePath) : Directory.current.path;

      _process = await Process.start(
        exePath,
        args,
        workingDirectory: workingDir,
      );

      if (!_runningStateController.isClosed) {
        _runningStateController.add(true);
      }
      appLogger.info('WindowsDpiService', 'PID: ${_process!.pid}');

      const decoder = Utf8Decoder(allowMalformed: true);

      _process!.stdout
          .transform(decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (!_logsController.isClosed) {
            _logsController.add(line);
          }
          appLogger.info(engineTag, line);
        },
        onError: (err) {
          appLogger.warning('WindowsDpiService', 'Stdout stream error: $err');
        },
      );

      _process!.stderr
          .transform(decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (!_logsController.isClosed) {
            _logsController.add('[STDERR] $line');
          }
          appLogger.warning(engineTag, line);
        },
        onError: (err) {
          appLogger.warning('WindowsDpiService', 'Stderr stream error: $err');
        },
      );

      _process!.exitCode.then((code) {
        appLogger.info('WindowsDpiService', 'Process exited with code $code');
        _process = null;
        if (!_runningStateController.isClosed) {
          _runningStateController.add(false);
        }
      });
    } catch (e) {
      _process = null;
      if (!_runningStateController.isClosed) {
        _runningStateController.add(false);
      }
      appLogger.severe('WindowsDpiService', 'Failed to launch DPI process: $e');
      throw Exception('Failed to start $engineTag: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_process == null) return;
    try {
      appLogger.info('WindowsDpiService', 'Stopping DPI process');
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          _process?.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (e) {
      appLogger.warning('WindowsDpiService', 'Error terminating process: $e');
    } finally {
      _process = null;
      if (!_runningStateController.isClosed) {
        _runningStateController.add(false);
      }
      appLogger.info('WindowsDpiService', 'DPI bypass stopped');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _process?.kill(ProcessSignal.sigkill);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _process?.kill(ProcessSignal.sigkill);
    _process = null;
    _runningStateController.close();
    _logsController.close();
  }
}
