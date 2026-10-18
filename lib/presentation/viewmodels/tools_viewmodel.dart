import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/public_ip_info.dart';
import '../../domain/entities/scheduled_shutdown_state.dart';
import '../../domain/services/cloudflare_scanner_service.dart';
import '../../domain/services/i_system_tools_service.dart';

class ToolsViewModel extends ChangeNotifier {
  final ISystemToolsService _toolsService;
  final ICloudflareScannerService? _cfScannerService;

  PublicIpInfo? _publicIpInfo;
  bool _isLoadingIp = false;
  ScheduledShutdownState _shutdownState = const ScheduledShutdownState.inactive();
  String? _errorMessage;
  String? _statusMessage;
  Timer? _countdownTimer;

  List<CloudflareCleanIp> _cleanIps = [];
  bool _isScanningIps = false;
  double _scanProgress = 0.0;
  StreamSubscription<double>? _progressSub;

  ToolsViewModel({
    required ISystemToolsService toolsService,
    ICloudflareScannerService? cfScannerService,
  })  : _toolsService = toolsService,
        _cfScannerService = cfScannerService {
    _progressSub = _cfScannerService?.progressStream.listen((progress) {
      _scanProgress = progress;
      notifyListeners();
    });
  }

  PublicIpInfo? get publicIpInfo => _publicIpInfo;
  bool get isLoadingIp => _isLoadingIp;
  ScheduledShutdownState get shutdownState => _shutdownState;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  List<CloudflareCleanIp> get cleanIps => _cleanIps;
  bool get isScanningIps => _isScanningIps;
  double get scanProgress => _scanProgress;

  Future<void> refreshPublicIp() async {
    _isLoadingIp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _publicIpInfo = await _toolsService.fetchPublicIpInfo();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch public IP details';
      appLogger.warning('ToolsViewModel', 'Error fetching public IP: $e');
    } finally {
      _isLoadingIp = false;
      notifyListeners();
    }
  }

  Future<void> scanCloudflareIps({int limit = 10}) async {
    if (_cfScannerService == null) return;
    _isScanningIps = true;
    _scanProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      _cleanIps = await _cfScannerService.scanCleanIps(limit: limit);
    } catch (e) {
      _errorMessage = 'Failed to scan Cloudflare clean IPs: $e';
      appLogger.warning('ToolsViewModel', 'Error scanning Cloudflare IPs: $e');
    } finally {
      _isScanningIps = false;
      notifyListeners();
    }
  }

  Future<bool> toggleInterface(String name, bool enable) async {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    final success = await _toolsService.setInterfaceStatus(name, enable);
    if (success) {
      _statusMessage = 'Interface $name ${enable ? "enabled" : "disabled"}';
    } else {
      _errorMessage = 'Failed to modify interface $name';
    }
    notifyListeners();
    return success;
  }

  Future<bool> scheduleShutdown(Duration delay, {String? reason}) async {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    final success = await _toolsService.scheduleShutdown(delay, reason: reason);
    if (success) {
      _shutdownState = ScheduledShutdownState.active(
        targetTime: DateTime.now().add(delay),
        reason: reason,
      );
      _statusMessage = 'System shutdown scheduled in ${delay.inMinutes} minutes';
      _startCountdown();
    } else {
      _errorMessage = 'Failed to schedule system shutdown';
    }
    notifyListeners();
    return success;
  }

  Future<bool> cancelShutdown() async {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    final success = await _toolsService.cancelShutdown();
    if (success) {
      _shutdownState = const ScheduledShutdownState.inactive();
      _statusMessage = 'Scheduled shutdown cancelled';
      _stopCountdown();
    } else {
      _errorMessage = 'Failed to cancel scheduled shutdown';
    }
    notifyListeners();
    return success;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_shutdownState.isActive) {
        timer.cancel();
        return;
      }
      final remaining = _shutdownState.remainingDuration;
      if (remaining == null || remaining.inSeconds <= 0) {
        _shutdownState = const ScheduledShutdownState.inactive();
        timer.cancel();
      }
      notifyListeners();
    });
  }

  void clearMessages() {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopCountdown();
    _progressSub?.cancel();
    super.dispose();
  }
}
