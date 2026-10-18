import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/system_tools_service_impl.dart';
import 'package:butterfly/domain/entities/public_ip_info.dart';
import 'package:butterfly/domain/entities/scheduled_shutdown_state.dart';
import 'package:butterfly/domain/services/i_system_tools_service.dart';
import 'package:butterfly/presentation/viewmodels/tools_viewmodel.dart';

class FakeSystemToolsService implements ISystemToolsService {
  PublicIpInfo? ipToReturn = const PublicIpInfo(
    ip: '198.51.100.1',
    city: 'Zurich',
    country: 'Switzerland',
    isp: 'Proton AG',
    asn: 'AS208323',
  );
  ScheduledShutdownState currentShutdown = const ScheduledShutdownState.inactive();
  bool throwOnIp = false;

  @override
  Future<PublicIpInfo> fetchPublicIpInfo({Duration timeout = const Duration(seconds: 8)}) async {
    if (throwOnIp) throw Exception('Network timeout');
    return ipToReturn!;
  }

  @override
  Future<bool> setInterfaceStatus(String interfaceName, bool enable) async {
    return true;
  }

  @override
  Future<bool> scheduleShutdown(Duration delay, {String? reason}) async {
    currentShutdown = ScheduledShutdownState.active(
      targetTime: DateTime.now().add(delay),
      reason: reason,
    );
    return true;
  }

  @override
  Future<bool> cancelShutdown() async {
    currentShutdown = const ScheduledShutdownState.inactive();
    return true;
  }

  @override
  Future<ScheduledShutdownState> getShutdownStatus() async {
    return currentShutdown;
  }
}

void main() {
  group('SystemToolsServiceImpl Commands', () {
    test('builds Windows shutdown and cancel commands', () {
      final cmd = SystemToolsServiceImpl.buildShutdownCommand(
        const Duration(minutes: 15),
        isWindows: true,
        reason: 'Maintenance',
      );
      expect(cmd, contains('shutdown /s /t 900'));
      expect(cmd, contains('/c "Maintenance"'));

      final cancelCmd = SystemToolsServiceImpl.buildCancelShutdownCommand(isWindows: true);
      expect(cancelCmd, equals('shutdown /a'));
    });

    test('builds Linux shutdown and cancel commands', () {
      final cmd = SystemToolsServiceImpl.buildShutdownCommand(
        const Duration(minutes: 30),
        isWindows: false,
      );
      expect(cmd, equals('shutdown -h +30'));

      final cancelCmd = SystemToolsServiceImpl.buildCancelShutdownCommand(isWindows: false);
      expect(cancelCmd, equals('shutdown -c'));

      final withReason = SystemToolsServiceImpl.buildShutdownCommand(
        const Duration(minutes: 30),
        isWindows: false,
        reason: 'Kernel update',
      );
      expect(withReason, equals('shutdown -h +30 "Kernel update"'));
    });

    test('builds adapter status command safely across OS', () {
      final winCmd = SystemToolsServiceImpl.buildSetInterfaceStatusCommand(
        'Ethernet 2',
        true,
        isWindows: true,
      );
      expect(winCmd, equals('netsh interface set interface name="Ethernet 2" admin=ENABLED'));

      final linuxCmd = SystemToolsServiceImpl.buildSetInterfaceStatusCommand(
        'wlp1s0',
        false,
        isWindows: false,
      );
      expect(linuxCmd, equals('nmcli dev disconnect wlp1s0'));
    });

    test('rejects malicious shell characters and quotes in commands', () {
      expect(
        () => SystemToolsServiceImpl.buildSetInterfaceStatusCommand(
          'eth0; reboot',
          true,
          isWindows: false,
        ),
        throwsArgumentError,
      );

      expect(
        () => SystemToolsServiceImpl.buildShutdownCommand(
          const Duration(minutes: 5),
          isWindows: true,
          reason: 'Maintenance" /t 0 /f "',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ToolsViewModel', () {
    test('loads public IP info and notifies listeners', () async {
      final fake = FakeSystemToolsService();
      final vm = ToolsViewModel(toolsService: fake);

      expect(vm.isLoadingIp, isFalse);
      expect(vm.publicIpInfo, isNull);

      final future = vm.refreshPublicIp();
      expect(vm.isLoadingIp, isTrue);

      await future;
      expect(vm.isLoadingIp, isFalse);
      expect(vm.publicIpInfo?.ip, equals('198.51.100.1'));
      expect(vm.publicIpInfo?.country, equals('Switzerland'));
      expect(vm.publicIpInfo?.isp, equals('Proton AG'));
      expect(vm.errorMessage, isNull);
    });

    test('handles public IP fetch errors gracefully', () async {
      final fake = FakeSystemToolsService()..throwOnIp = true;
      final vm = ToolsViewModel(toolsService: fake);

      await vm.refreshPublicIp();
      expect(vm.isLoadingIp, isFalse);
      expect(vm.publicIpInfo, isNull);
      expect(vm.errorMessage, isNotNull);
    });

    test('schedules and cancels system shutdown', () async {
      final fake = FakeSystemToolsService();
      final vm = ToolsViewModel(toolsService: fake);

      await vm.scheduleShutdown(const Duration(minutes: 60), reason: 'Scheduled Test');
      expect(vm.shutdownState.isActive, isTrue);
      expect(vm.shutdownState.reason, equals('Scheduled Test'));

      await vm.cancelShutdown();
      expect(vm.shutdownState.isActive, isFalse);
    });
  });
}
