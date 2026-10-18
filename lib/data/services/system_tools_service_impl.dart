import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/utils/logger.dart';
import '../../domain/entities/public_ip_info.dart';
import '../../domain/entities/scheduled_shutdown_state.dart';
import '../../domain/services/i_system_tools_service.dart';

class SystemToolsServiceImpl implements ISystemToolsService {
  ScheduledShutdownState _shutdownState = const ScheduledShutdownState.inactive();

  static final RegExp _disallowedCharsRegex = RegExp(r'[;&|`$><]');

  static String sanitizeInput(String input) {
    if (_disallowedCharsRegex.hasMatch(input)) {
      throw ArgumentError('Input contains disallowed shell metacharacters: $input');
    }
    return input.trim();
  }

  static String buildShutdownCommand(
    Duration delay, {
    bool? isWindows,
    String? reason,
  }) {
    final win = isWindows ?? Platform.isWindows;
    final seconds = delay.inSeconds;

    if (win) {
      final sanitizedReason = reason != null ? sanitizeInput(reason) : null;
      final reasonPart = sanitizedReason != null ? ' /c "$sanitizedReason"' : '';
      return 'shutdown /s /t $seconds$reasonPart';
    } else {
      final minutes = max(1, (seconds / 60).ceil());
      return 'shutdown -h +$minutes';
    }
  }

  static String buildCancelShutdownCommand({bool? isWindows}) {
    final win = isWindows ?? Platform.isWindows;
    return win ? 'shutdown /a' : 'shutdown -c';
  }

  static String buildSetInterfaceStatusCommand(
    String interfaceName,
    bool enable, {
    bool? isWindows,
  }) {
    final win = isWindows ?? Platform.isWindows;
    final cleanName = sanitizeInput(interfaceName);

    if (win) {
      final action = enable ? 'ENABLED' : 'DISABLED';
      return 'netsh interface set interface name="$cleanName" admin=$action';
    } else {
      final action = enable ? 'connect' : 'disconnect';
      return 'nmcli dev $action $cleanName';
    }
  }

  @override
  Future<PublicIpInfo> fetchPublicIpInfo({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = timeout;

      try {
        final req = await client.getUrl(Uri.parse('https://ip.wtf/'));
        req.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final res = await req.close().timeout(timeout);

        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          return PublicIpInfo.fromJson(decoded);
        }
      } catch (_) {}

      // Fallback endpoint
      final req2 = await client.getUrl(Uri.parse('https://api.ipify.org?format=json'));
      final res2 = await req2.close().timeout(timeout);
      if (res2.statusCode == 200) {
        final body = await res2.transform(utf8.decoder).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return PublicIpInfo.fromJson(decoded);
      }

      throw const SocketException('Failed to retrieve public IP address');
    } finally {
      client?.close(force: true);
    }
  }

  @override
  Future<bool> setInterfaceStatus(String interfaceName, bool enable) async {
    final command = buildSetInterfaceStatusCommand(interfaceName, enable);
    appLogger.info('SystemToolsService', 'Setting interface status: $command');

    try {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run('cmd', ['/c', command]);
      } else {
        result = await Process.run('sh', ['-c', command]);
        if (result.exitCode != 0) {
          result = await Process.run('pkexec', ['sh', '-c', command]);
        }
      }
      return result.exitCode == 0;
    } catch (e) {
      appLogger.severe('SystemToolsService', 'Error setting interface status: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleShutdown(Duration delay, {String? reason}) async {
    final command = buildShutdownCommand(delay, reason: reason);
    appLogger.info('SystemToolsService', 'Scheduling shutdown: $command');

    try {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run('cmd', ['/c', command]);
      } else {
        result = await Process.run('sh', ['-c', command]);
        if (result.exitCode != 0) {
          result = await Process.run('pkexec', ['sh', '-c', command]);
        }
      }

      if (result.exitCode == 0) {
        _shutdownState = ScheduledShutdownState.active(
          targetTime: DateTime.now().add(delay),
          reason: reason,
        );
        return true;
      }
      return false;
    } catch (e) {
      appLogger.severe('SystemToolsService', 'Error scheduling shutdown: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelShutdown() async {
    final command = buildCancelShutdownCommand();
    appLogger.info('SystemToolsService', 'Canceling shutdown: $command');

    try {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run('cmd', ['/c', command]);
      } else {
        result = await Process.run('sh', ['-c', command]);
        if (result.exitCode != 0) {
          result = await Process.run('pkexec', ['sh', '-c', command]);
        }
      }
      _shutdownState = const ScheduledShutdownState.inactive();
      return true;
    } catch (e) {
      appLogger.severe('SystemToolsService', 'Error canceling shutdown: $e');
      return false;
    }
  }

  @override
  Future<ScheduledShutdownState> getShutdownStatus() async {
    return _shutdownState;
  }
}
