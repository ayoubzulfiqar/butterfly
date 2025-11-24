import '../../data/repositories/dns_service.dart';
import '../../data/models/dpi_bypass_mode.dart';

/// Use case to start DPI bypass.
class StartDpiBypassUseCase {
  final DnsService dnsService;

  StartDpiBypassUseCase(this.dnsService);

  Future<void> execute(DpiBypassMode mode) async {
    await dnsService.startDpiBypass(mode);
  }
}