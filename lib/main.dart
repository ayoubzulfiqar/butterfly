import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/logger.dart';
import 'core/themes/app_theme.dart';
import 'data/repositories/dns_provider_repository.dart';
import 'data/repositories/dns_service.dart';
import 'domain/usecases/get_dns_providers_usecase.dart';
import 'domain/usecases/change_dns_usecase.dart';
import 'domain/usecases/restore_dns_usecase.dart';
import 'domain/usecases/get_current_dns_usecase.dart';
import 'domain/usecases/get_adapters_usecase.dart';
import 'domain/usecases/start_dpi_bypass_usecase.dart';
import 'domain/usecases/stop_dpi_bypass_usecase.dart';
import 'presentation/viewmodels/dns_changer_viewmodel.dart';
import 'presentation/views/dns_changer_screen.dart';

void main() {
  setupLogging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DnsProviderRepository()),
        Provider(create: (_) => DnsService()),
        ProxyProvider<DnsProviderRepository, GetDnsProvidersUseCase>(
          update: (_, repo, _) => GetDnsProvidersUseCase(repo),
        ),
        ProxyProvider<DnsService, ChangeDnsUseCase>(
          update: (_, service, _) => ChangeDnsUseCase(service),
        ),
        ProxyProvider<DnsService, RestoreDnsUseCase>(
          update: (_, service, _) => RestoreDnsUseCase(service),
        ),
        ProxyProvider<DnsService, GetCurrentDnsUseCase>(
          update: (_, service, _) => GetCurrentDnsUseCase(service),
        ),
        ProxyProvider<DnsService, GetAdaptersUseCase>(
          update: (_, service, _) => GetAdaptersUseCase(service),
        ),
        ProxyProvider<DnsService, StartDpiBypassUseCase>(
          update: (_, service, _) => StartDpiBypassUseCase(service),
        ),
        ProxyProvider<DnsService, StopDpiBypassUseCase>(
          update: (_, service, _) => StopDpiBypassUseCase(service),
        ),
        ChangeNotifierProvider<DnsChangerViewModel>(
          create: (context) => DnsChangerViewModel(
            dnsProviderRepository: context.read<DnsProviderRepository>(),
            dnsService: context.read<DnsService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'DNS Changer',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DnsChangerScreen(),
      ),
    );
  }
}
