import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/app_log_entry.dart';

/// ViewModel managing real-time diagnostic logs and telemetry.
class DiagnosticsViewModel extends ChangeNotifier {
  final List<AppLogEntry> _logs = [];
  StreamSubscription<AppLogEntry>? _logSub;

  LogSeverity? _filterSeverity;
  String _searchFilter = '';

  DiagnosticsViewModel() {
    _logs.addAll(appLogger.recentLogs);
    _logSub = appLogger.logStream.listen((entry) {
      _logs.add(entry);
      if (_logs.length > 1000) {
        _logs.removeAt(0);
      }
      notifyListeners();
    });
  }

  List<AppLogEntry> get allLogs => List.unmodifiable(_logs);
  LogSeverity? get filterSeverity => _filterSeverity;
  String get searchFilter => _searchFilter;

  List<AppLogEntry> get filteredLogs {
    return _logs.where((entry) {
      final matchesSeverity = _filterSeverity == null ||
          entry.severity == _filterSeverity;
      final matchesSearch = _searchFilter.isEmpty ||
          entry.message.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          entry.tag.toLowerCase().contains(_searchFilter.toLowerCase());
      return matchesSeverity && matchesSearch;
    }).toList().reversed.toList();
  }

  void setFilterSeverity(LogSeverity? severity) {
    _filterSeverity = severity;
    notifyListeners();
  }

  void setSearchFilter(String query) {
    _searchFilter = query;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    appLogger.clear();
    notifyListeners();
  }

  String getFormattedLogsText() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(
        '[${log.formattedTime}][${log.severity.name.toUpperCase()}][${log.tag}] ${log.message}',
      );
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }
}
