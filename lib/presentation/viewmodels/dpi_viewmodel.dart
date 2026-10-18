import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/dpi_bypass_mode.dart';
import '../../domain/entities/zapret2_strategy.dart';
import '../../domain/services/i_dpi_service.dart';

/// ViewModel controlling DPI bypass execution and status monitoring.
class DpiViewModel extends ChangeNotifier {
  final IDpiService dpiService;
  StreamSubscription<bool>? _runningSub;

  String _selectedEngine = 'zapret2';
  Zapret2Strategy _selectedStrategy = Zapret2Strategies.strong;
  bool _enableQuic = true;
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

  String get selectedEngine => _selectedEngine;
  bool get isZapret2 => _selectedEngine == 'zapret2';
  Zapret2Strategy get selectedStrategy => _selectedStrategy;
  Zapret2Profile get selectedProfile => _selectedStrategy.profile;
  bool get enableQuic => _enableQuic;
  DpiBypassMode get selectedMode => _selectedMode;
  List<DpiBypassMode> get availableModes => DpiBypassModes.all;
  bool get isRunning => _isRunning;
  bool get isLoading => _isLoading;
  bool get isExecutableAvailable => _isExecutableAvailable;
  String get statusMessage => _statusMessage;

  String get cliPreview {
    if (isZapret2) {
      final buffer = StringBuffer();
      buffer.write('zapret2: ');
      buffer.writeAll(_selectedStrategy.tcpArgs, ' ');
      if (_enableQuic && _selectedStrategy.quicArgs.isNotEmpty) {
        buffer.write(' ');
        buffer.writeAll(_selectedStrategy.quicArgs, ' ');
      }
      return buffer.toString();
    } else {
      return 'goodbyedpi ${_selectedMode.args.join(' ')}';
    }
  }

  Future<void> checkExecutable() async {
    _isExecutableAvailable = await dpiService.isExecutableAvailable();
    notifyListeners();
  }

  void selectEngine(String engine) {
    if (_selectedEngine != engine) {
      _selectedEngine = engine;
      notifyListeners();
    }
  }

  void selectProfile(Zapret2Profile profile) {
    _selectedStrategy = Zapret2Strategies.fromProfile(profile);
    notifyListeners();
  }

  void selectStrategy(Zapret2Strategy strategy) {
    _selectedStrategy = strategy;
    notifyListeners();
  }

  void setEnableQuic(bool value) {
    _enableQuic = value;
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
      if (isZapret2) {
        await dpiService.startZapret2(
          _selectedStrategy,
          enableQuic: _enableQuic,
        );
        _statusMessage = 'Started zapret2 (${_selectedStrategy.name})';
      } else {
        await dpiService.start(_selectedMode);
        _statusMessage = 'Started DPI Bypass (${_selectedMode.name})';
      }
      return true;
    } catch (e) {
      _statusMessage = '$e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleBypass() async {
    if (_isRunning) {
      return stopBypass();
    } else {
      return startBypass();
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
