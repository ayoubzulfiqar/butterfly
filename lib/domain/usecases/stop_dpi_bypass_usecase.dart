import '../../data/repositories/dns_service.dart';

/// Use case to stop DPI bypass.
class StopDpiBypassUseCase {
  final DnsService dnsService;

  StopDpiBypassUseCase(this.dnsService);

  Future<void> execute() async {
    await dnsService.stopDpiBypass();
  }
}