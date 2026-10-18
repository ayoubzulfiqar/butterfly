import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as dart_logging;
import '../../domain/entities/app_log_entry.dart';

/// Application logging controller that streams structured log entries.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  AppLogger._internal();

  final _controller = StreamController<AppLogEntry>.broadcast();
  final List<AppLogEntry> _recentLogs = [];

  Stream<AppLogEntry> get logStream => _controller.stream;
  List<AppLogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  void _add(LogSeverity severity, String tag, String message) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      severity: severity,
      tag: tag,
      message: message,
    );
    _recentLogs.add(entry);
    if (_recentLogs.length > 500) {
      _recentLogs.removeAt(0);
    }
    _controller.add(entry);

    if (kDebugMode) {
      debugPrint('[${severity.name.toUpperCase()}][$tag] $message');
    }
  }

  void info(String tag, String message) {
    _add(LogSeverity.info, tag, message);
  }

  void warning(String tag, String message) {
    _add(LogSeverity.warning, tag, message);
  }

  void severe(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final errStr = error != null ? ' ($error)' : '';
    _add(LogSeverity.error, tag, '$message$errStr');
  }

  void clear() {
    _recentLogs.clear();
  }
}

/// Global AppLogger instance.
final appLogger = AppLogger();

/// Legacy package:logging logger bridge.
final logger = dart_logging.Logger('DnsChanger');

/// Initializes logging and hooks dart_logging into the AppLogger stream.
void setupLogging() {
  dart_logging.Logger.root.level = dart_logging.Level.ALL;
  dart_logging.Logger.root.onRecord.listen((record) {
    if (record.level >= dart_logging.Level.SEVERE) {
      appLogger.severe(
        record.loggerName,
        record.message,
        record.error,
        record.stackTrace,
      );
    } else if (record.level >= dart_logging.Level.WARNING) {
      appLogger.warning(record.loggerName, record.message);
    } else {
      appLogger.info(record.loggerName, record.message);
    }
  });
}
