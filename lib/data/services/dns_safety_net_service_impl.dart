import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../domain/entities/network_adapter.dart';
import '../../domain/services/dns_safety_net_service.dart';
import '../../domain/services/i_network_service.dart';

/// Concrete implementation of the bulletproof DNS safety net.
class DnsSafetyNetServiceImpl implements IDnsSafetyNetService {
  final File _stateFile;

  DnsSafetyNetServiceImpl({File? stateFile})
      : _stateFile = stateFile ?? _defaultStateFile();

  static File _defaultStateFile() {
    String dir;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
      dir = path.join(appData, 'butterfly');
    } else {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      dir = path.join(home, '.config', 'butterfly');
    }
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File(path.join(dir, 'state.json'));
  }

  @override
  Future<void> snapshotCurrentDns(NetworkAdapter adapter) async {
    try {
      final snapshot = DnsSnapshot(
        interfaceName: adapter.name,
        isDhcp: adapter.isDhcp,
        dnsServers: adapter.dnsServers,
        timestamp: DateTime.now(),
      );

      final parent = _stateFile.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }

      await _stateFile.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
      appLogger.info('SafetyNet', 'Saved DNS snapshot for ${adapter.name} to ${_stateFile.path}');
    } catch (e) {
      appLogger.severe('SafetyNet', 'Failed to save DNS snapshot: $e');
    }
  }

  @override
  Future<bool> hasPendingRestore() async {
    return _stateFile.existsSync();
  }

  @override
  Future<DnsSnapshot?> readSnapshot() async {
    if (!_stateFile.existsSync()) return null;
    try {
      final content = await _stateFile.readAsString();
      if (content.trim().isEmpty) return null;
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DnsSnapshot.fromJson(json);
    } catch (e) {
      appLogger.warning('SafetyNet', 'Corrupt or unreadable snapshot file: $e');
      return null;
    }
  }

  @override
  Future<bool> restoreOriginalDns(INetworkService networkService) async {
    final snapshot = await readSnapshot();
    if (snapshot == null) {
      await clearSnapshot();
      return false;
    }

    try {
      appLogger.info('SafetyNet', 'Restoring original DNS for ${snapshot.interfaceName}...');
      if (snapshot.isDhcp || snapshot.dnsServers.isEmpty) {
        await networkService.restoreDns(snapshot.interfaceName);
      } else {
        final ipv4 = <String>[];
        final ipv6 = <String>[];
        for (final s in snapshot.dnsServers) {
          if (s.contains(':')) {
            ipv6.add(s);
          } else {
            ipv4.add(s);
          }
        }
        await networkService.setDns(snapshot.interfaceName, ipv4, ipv6);
      }
      await clearSnapshot();
      appLogger.info('SafetyNet', 'Successfully restored DNS and cleared snapshot');
      return true;
    } catch (e) {
      appLogger.severe('SafetyNet', 'Failed to restore DNS from snapshot: $e');
      return false;
    }
  }

  @override
  Future<void> clearSnapshot() async {
    try {
      if (_stateFile.existsSync()) {
        await _stateFile.delete();
      }
    } catch (e) {
      appLogger.warning('SafetyNet', 'Failed to delete snapshot file: $e');
    }
  }
}
