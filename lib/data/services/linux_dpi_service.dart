import 'dart:async';

import '../../core/utils/logger.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/services/i_dpi_service.dart';

class LinuxDpiService implements IDpiService {
  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  @override
  bool get isRunning => false;

  @override
  Stream<bool> get runningStateStream => _runningController.stream;

  @override
  Stream<String> get processLogsStream => _logController.stream;

  @override
  Future<bool> isExecutableAvailable() async {
    return false;
  }

  @override
  Future<void> start(DpiBypassMode mode) async {
    appLogger.warning(
      'LinuxDpiService',
      'GoodbyeDPI is designed for Windows WinDivert. On Linux, use zapret or ciadpi for DPI bypass.',
    );
    _logController.add(
      '[NOTICE] GoodbyeDPI uses Windows WinDivert driver. '
      'On Linux, consider native tools like zapret or ciadpi.',
    );
  }

  @override
  Future<void> stop() async {
    // No-op on Linux
  }

  @override
  void dispose() {
    _runningController.close();
    _logController.close();
  }
}
