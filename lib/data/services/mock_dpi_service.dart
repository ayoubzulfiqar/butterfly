import 'dart:async';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/services/i_dpi_service.dart';

/// In-memory mock implementation of [IDpiService] for testing.
class MockDpiService implements IDpiService {
  bool _isRunning = false;
  final _stateController = StreamController<bool>.broadcast();
  final _logsController = StreamController<String>.broadcast();

  @override
  bool get isRunning => _isRunning;

  @override
  Stream<bool> get runningStateStream => _stateController.stream;

  @override
  Stream<String> get processLogsStream => _logsController.stream;

  @override
  Future<bool> isExecutableAvailable() async => true;

  @override
  Future<void> start(DpiBypassMode mode) async {
    _isRunning = true;
    _stateController.add(true);
    _logsController.add('Started DPI Bypass with mode: ${mode.name}');
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _stateController.add(false);
    _logsController.add('Stopped DPI Bypass');
  }

  @override
  void dispose() {
    _stateController.close();
    _logsController.close();
  }
}
