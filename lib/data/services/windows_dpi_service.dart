import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/services/i_dpi_service.dart';

/// Service managing the lifecycle of GoodbyeDPI on Windows.
class WindowsDpiService with WidgetsBindingObserver implements IDpiService {
  Process? _process;
  final _runningStateController = StreamController<bool>.broadcast();
  final _logsController = StreamController<String>.broadcast();

  WindowsDpiService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  bool get isRunning => _process != null;

  @override
  Stream<bool> get runningStateStream => _runningStateController.stream;

  @override
  Stream<String> get processLogsStream => _logsController.stream;

  /// Resolves the file path to goodbyedpi.exe across common locations.
  String? getExecutablePath() {
    final candidatePaths = [
      path.join(path.dirname(Platform.resolvedExecutable), 'goodbyedpi.exe'),
      path.join(Directory.current.path, 'goodbyedpi.exe'),
      path.join(Directory.current.path, 'assets', 'bin', 'goodbyedpi.exe'),
      path.join(
        path.dirname(Platform.resolvedExecutable),
        'data',
        'flutter_assets',
        'assets',
        'bin',
        'goodbyedpi.exe',
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
    return getExecutablePath() != null;
  }

  @override
  Future<void> start(DpiBypassMode mode) async {
    if (_process != null) {
      appLogger.info('WindowsDpiService', 'DPI bypass is already active');
      return;
    }

    final exePath = getExecutablePath();
    if (exePath == null) {
      const err = 'goodbyedpi.exe was not found in application directory. '
          'Please place goodbyedpi.exe alongside the app executable.';
      appLogger.severe('WindowsDpiService', err);
      throw Exception(err);
    }

    try {
      appLogger.info(
        'WindowsDpiService',
        'Launching DPI bypass (${mode.name}): $exePath ${mode.args.join(' ')}',
      );

      _process = await Process.start(
        exePath,
        mode.args,
        workingDirectory: path.dirname(exePath),
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
          appLogger.info('GoodbyeDPI', line);
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
          appLogger.warning('GoodbyeDPI', line);
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
      throw Exception('Failed to start DPI bypass: $e');
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
      // Ensure no zombie GoodbyeDPI process remains running on app exit
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
