import 'package:butterfly/domain/entities/public_ip_info.dart';
import 'package:butterfly/domain/entities/scheduled_shutdown_state.dart';

abstract class ISystemToolsService {
  Future<PublicIpInfo> fetchPublicIpInfo({
    Duration timeout = const Duration(seconds: 8),
  });

  Future<bool> setInterfaceStatus(String interfaceName, bool enable);

  Future<bool> scheduleShutdown(Duration delay, {String? reason});

  Future<bool> cancelShutdown();

  Future<ScheduledShutdownState> getShutdownStatus();
}
