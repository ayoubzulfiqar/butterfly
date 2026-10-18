import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/domain/entities/dpi_bypass_mode.dart';

void main() {
  test('MockDpiService starts and emits running state transitions', () async {
    final service = MockDpiService();
    expect(service.isRunning, isFalse);

    final states = <bool>[];
    final sub = service.runningStateStream.listen(states.add);

    await service.start(DpiBypassModes.standard);
    expect(service.isRunning, isTrue);

    await service.stop();
    expect(service.isRunning, isFalse);

    await sub.cancel();
    expect(states, [true, false]);
  });

  test('MockDpiService emits log messages during bypass', () async {
    final service = MockDpiService();
    final logs = <String>[];
    final sub = service.processLogsStream.listen(logs.add);

    await service.start(DpiBypassModes.basic);
    expect(logs.any((l) => l.contains('Started')), isTrue);

    await service.stop();
    expect(logs.any((l) => l.contains('Stopped')), isTrue);
    await sub.cancel();
  });

  test('MockDpiService reports executable available', () async {
    final service = MockDpiService();
    expect(await service.isExecutableAvailable(), isTrue);
  });
}
