import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../models/dpi_bypass_mode.dart';

/// Service for DNS operations on Windows using netsh commands.
class DnsService {
  Process? _dpiProcess;

  /// Check if DPI bypass is running
  bool get isDpiBypassRunning => _dpiProcess != null;

  /// Start DPI bypass using GoodbyeDPI with specified mode
  Future<void> startDpiBypass(DpiBypassMode mode) async {
    if (_dpiProcess != null) {
      logger.info('DPI bypass already running');
      return;
    }

    try {
      // Get the directory where the executable is located
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final exePath = path.join(exeDir, 'goodbyedpi.exe');

      // Check if the file exists
      if (!File(exePath).existsSync()) {
        throw Exception('goodbyedpi.exe not found in application directory');
      }

      final args = mode.args;

      logger.info('Starting DPI bypass: $exePath ${args.join(' ')}');
      _dpiProcess = await Process.start(exePath, args);
      logger.info('DPI bypass started with PID: ${_dpiProcess!.pid}');

      // Listen for exit
      _dpiProcess!.exitCode.then((code) {
        logger.info('DPI bypass exited with code: $code');
        _dpiProcess = null;
      });
    } catch (e) {
      logger.severe('Failed to start DPI bypass: $e');
      throw Exception('Failed to start DPI bypass: $e');
    }
  }

  /// Stop DPI bypass
  Future<void> stopDpiBypass() async {
    if (_dpiProcess == null) {
      logger.info('DPI bypass not running');
      return;
    }

    logger.info('Stopping DPI bypass');
    _dpiProcess!.kill();
    await _dpiProcess!.exitCode;
    _dpiProcess = null;
    logger.info('DPI bypass stopped');
  }
  /// Sets the DNS servers for the given adapter.
  Future<void> setDns(String adapter, List<String> ipv4, List<String> ipv6) async {
    logger.info('Setting DNS for adapter: $adapter, IPv4: $ipv4, IPv6: $ipv6');
    if (ipv4.isNotEmpty) {
      final ipv4String = ipv4.map((ip) => '"$ip"').join(',');
      final command = 'Set-DnsClientServerAddress -InterfaceAlias "$adapter" -ServerAddresses ($ipv4String)';
      logger.info('Running PowerShell command: $command');
      final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command]);
      logger.info('Command result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}');
      if (result.exitCode != 0) {
        final errorMsg = result.stderr.toString().isNotEmpty ? result.stderr : 'Access denied or invalid adapter name. Please check adapter name and ensure you are running as Administrator.';
        throw Exception('Failed to set IPv4 DNS: $errorMsg');
      }
    }

    if (ipv6.isNotEmpty) {
      final ipv6String = ipv6.map((ip) => '"$ip"').join(',');
      final command = 'Set-DnsClientServerAddress -InterfaceAlias "$adapter" -ServerAddresses ($ipv6String)';
      logger.info('Running PowerShell command: $command');
      final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command]);
      logger.info('Command result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}');
      if (result.exitCode != 0) {
        final errorMsg = result.stderr.toString().isNotEmpty ? result.stderr : 'Access denied or invalid adapter name. Please check adapter name and ensure you are running as Administrator.';
        throw Exception('Failed to set IPv6 DNS: $errorMsg');
      }
    }

    // Flush DNS cache to ensure changes take effect immediately
    logger.info('Flushing DNS cache');
    final flushResult = await Process.run('ipconfig', ['/flushdns']);
    logger.info('Flush DNS result: exitCode=${flushResult.exitCode}, stdout=${flushResult.stdout}, stderr=${flushResult.stderr}');
    if (flushResult.exitCode != 0) {
      logger.warning('Failed to flush DNS cache: ${flushResult.stderr}');
    }
  }

  /// Restores DNS to DHCP for the given adapter.
  Future<void> restoreDns(String adapter) async {
    logger.info('Restoring DNS for adapter: $adapter');
    final command = 'Set-DnsClientServerAddress -InterfaceAlias "$adapter" -ResetServerAddresses';
    logger.info('Running PowerShell command: $command');
    final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command]);
    logger.info('Restore result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}');
    if (result.exitCode != 0) {
      final errorMsg = result.stderr.toString().isNotEmpty ? result.stderr : 'Access denied. Please run the app as Administrator.';
      throw Exception('Failed to restore DNS: $errorMsg');
    }

    // Flush DNS cache after restore
    logger.info('Flushing DNS cache after restore');
    final flushResult = await Process.run('ipconfig', ['/flushdns']);
    logger.info('Flush DNS result: exitCode=${flushResult.exitCode}, stdout=${flushResult.stdout}, stderr=${flushResult.stderr}');
    if (flushResult.exitCode != 0) {
      logger.warning('Failed to flush DNS cache: ${flushResult.stderr}');
    }
  }

  /// Gets the current DNS configuration for the adapter.
  Future<String> getCurrentDns(String adapter) async {
    logger.info('Getting current DNS for adapter: $adapter');
    final command = 'Get-DnsClientServerAddress -InterfaceAlias "$adapter" | Select-Object -ExpandProperty ServerAddresses';
    logger.info('Running PowerShell command: $command');
    final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command]);
    logger.info('Get DNS result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}');
    if (result.exitCode != 0) {
      throw Exception('Failed to get DNS: ${result.stderr}');
    }
    return result.stdout as String;
  }

  /// Gets a list of available network adapters.
  Future<List<String>> getAdapters() async {
    logger.info('Getting network adapters');
    final command = r'Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty Name';
    logger.info('Running PowerShell command: $command');
    final result = await Process.run('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command]);
    if (result.exitCode != 0) {
      logger.severe('Failed to get adapters: ${result.stderr}');
      throw Exception('Failed to get adapters: ${result.stderr}');
    }
    logger.info('PowerShell output: ${result.stdout}');
    final adapters = (result.stdout as String).split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    logger.info('Total adapters found: ${adapters.length}');
    for (var adapter in adapters) {
      logger.info('Found connected adapter: $adapter');
    }
    return adapters;
  }
}