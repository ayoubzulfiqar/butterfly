import 'package:logging/logging.dart';

/// Logger setup for the app.
final logger = Logger('DnsChanger');

/// Sets up logging configuration.
void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
