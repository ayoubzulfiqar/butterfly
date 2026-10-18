import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/mock_dpi_service.dart';
import 'package:butterfly/domain/entities/dpi_bypass_mode.dart';
import 'package:butterfly/presentation/viewmodels/dpi_viewmodel.dart';

void main() {
  test('DpiViewModel initializes and starts/stops bypass', () async {
    final dpiService = MockDpiService();
    final vm = DpiViewModel(dpiService: dpiService);

    await vm.checkExecutable();
    expect(vm.isExecutableAvailable, isTrue);
    expect(vm.isRunning, isFalse);

    vm.selectMode(DpiBypassModes.universal);
    expect(vm.selectedMode.id, 'universal');

    await vm.startBypass();
    expect(vm.isRunning, isTrue);

    await vm.stopBypass();
    expect(vm.isRunning, isFalse);
  });
}
