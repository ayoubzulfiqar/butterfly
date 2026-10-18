/// Severity levels for application logs.
enum LogSeverity { info, warning, error }

/// Represents an immutable log entry in the system.
class AppLogEntry {
  final DateTime timestamp;
  final LogSeverity severity;
  final String tag;
  final String message;

  const AppLogEntry({
    required this.timestamp,
    required this.severity,
    required this.tag,
    required this.message,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
