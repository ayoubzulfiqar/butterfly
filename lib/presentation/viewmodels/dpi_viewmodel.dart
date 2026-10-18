import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/services/i_dpi_service.dart';

/// ViewModel controlling DPI bypass execution and status monitoring.
class DpiViewModel extends ChangeNotifier {
  final IDpiService dpiService;
  StreamSubscription<bool>? _runningSub;

  DpiBypassMode _selectedMode = DpiBypassModes.standard;
  bool _isRunning = false;
  bool _isLoading = false;
  bool _isExecutableAvailable = false;
  String _statusMessage = '';

  DpiViewModel({required this.dpiService}) {
    _isRunning = dpiService.isRunning;
    _runningSub = dpiService.runningStateStream.listen((running) {
      _isRunning = running;
      _isLoading = false;
      notifyListeners();
    });
    checkExecutable();
  }

  DpiBypassMode get selectedMode => _selectedMode;
  List<DpiBypassMode> get availableModes => DpiBypassModes.all;
  bool get isRunning => _isRunning;
  bool get isLoading => _isLoading;
  bool get isExecutableAvailable => _isExecutableAvailable;
  String get statusMessage => _statusMessage;

  Future<void> checkExecutable() async {
    _isExecutableAvailable = await dpiService.isExecutableAvailable();
    notifyListeners();
  }

  void selectMode(DpiBypassMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  Future<bool> startBypass() async {
    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      await dpiService.start(_selectedMode);
      _statusMessage = 'Started DPI Bypass (${_selectedMode.name})';
      return true;
    } catch (e) {
      _statusMessage = '$e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> stopBypass() async {
    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      await dpiService.stop();
      _statusMessage = 'DPI Bypass stopped';
      return true;
    } catch (e) {
      _statusMessage = '$e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _runningSub?.cancel();
    super.dispose();
  }
}
