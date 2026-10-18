import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/public_ip_info.dart';
import '../../domain/entities/scheduled_shutdown_state.dart';
import '../../domain/services/i_system_tools_service.dart';

class ToolsViewModel extends ChangeNotifier {
  final ISystemToolsService _toolsService;

  PublicIpInfo? _publicIpInfo;
  bool _isLoadingIp = false;
  ScheduledShutdownState _shutdownState = const ScheduledShutdownState.inactive();
  String? _errorMessage;
  String? _statusMessage;
  Timer? _countdownTimer;

  ToolsViewModel({required ISystemToolsService toolsService})
      : _toolsService = toolsService;

  PublicIpInfo? get publicIpInfo => _publicIpInfo;
  bool get isLoadingIp => _isLoadingIp;
  ScheduledShutdownState get shutdownState => _shutdownState;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

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
      _shutdownState = await _toolsService.getShutdownStatus();
      _statusMessage = 'Shutdown successfully scheduled';
      _startCountdownTicker();
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
      _stopCountdownTicker();
      _shutdownState = const ScheduledShutdownState.inactive();
      _statusMessage = 'Scheduled shutdown cancelled';
    } else {
      _errorMessage = 'Failed to cancel scheduled shutdown';
    }
    notifyListeners();
    return success;
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _shutdownState.remainingDuration;
      if (!_shutdownState.isActive ||
          remaining == null ||
          remaining.inSeconds <= 0) {
        timer.cancel();
        _shutdownState = const ScheduledShutdownState.inactive();
      }
      notifyListeners();
    });
  }

  void _stopCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopCountdownTicker();
    super.dispose();
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }
}
