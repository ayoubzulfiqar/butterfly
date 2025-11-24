import '../../data/repositories/dns_service.dart';

/// Use case to start DPI bypass.
class StartDpiBypassUseCase {
  final DnsService dnsService;

  StartDpiBypassUseCase(this.dnsService);

  Future<void> execute() async {
    await dnsService.startDpiBypass();
  }
}