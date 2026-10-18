import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/logger.dart';
import 'data/repositories/dns_provider_repository_impl.dart';
import 'data/services/mock_dpi_service.dart';
import 'data/services/mock_network_service.dart';
import 'data/services/windows_dpi_service.dart';
import 'data/services/windows_network_service.dart';
import 'domain/repositories/i_dns_provider_repository.dart';
import 'domain/services/i_dpi_service.dart';
import 'domain/services/i_network_service.dart';
import 'presentation/viewmodels/diagnostics_viewmodel.dart';
import 'presentation/viewmodels/dpi_viewmodel.dart';
import 'presentation/viewmodels/navigation_viewmodel.dart';
import 'presentation/viewmodels/network_dns_viewmodel.dart';
import 'presentation/views/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  runApp(const ButterflyApp());
}

class ButterflyApp extends StatefulWidget {
  final INetworkService? networkService;
  final IDpiService? dpiService;
  final IDnsProviderRepository? repository;

  const ButterflyApp({
    super.key,
    this.networkService,
    this.dpiService,
    this.repository,
  });

  @override
  State<ButterflyApp> createState() => _ButterflyAppState();
}

class _ButterflyAppState extends State<ButterflyApp> {
  late final INetworkService _networkService;
  late final IDpiService _dpiService;
  late final IDnsProviderRepository _repository;

  @override
  void initState() {
    super.initState();
    _networkService = widget.networkService ??
        (Platform.isWindows
            ? WindowsNetworkService()
            : MockNetworkService());

    _dpiService = widget.dpiService ??
        (Platform.isWindows ? WindowsDpiService() : MockDpiService());

    _repository = widget.repository ?? DnsProviderRepositoryImpl();
  }

  @override
  void dispose() {
    _dpiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NavigationViewModel>(
          create: (_) => NavigationViewModel(),
        ),
        ChangeNotifierProvider<NetworkDnsViewModel>(
          create: (_) => NetworkDnsViewModel(
            networkService: _networkService,
            repository: _repository,
          )..loadInitialData(),
        ),
        ChangeNotifierProvider<DpiViewModel>(
          create: (_) => DpiViewModel(dpiService: _dpiService),
        ),
        ChangeNotifierProvider<DiagnosticsViewModel>(
          create: (_) => DiagnosticsViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Butterfly - Enterprise DNS Suite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fluentLight,
        darkTheme: AppTheme.fluentDark,
        themeMode: ThemeMode.system,
        home: const MainShellScreen(),
      ),
    );
  }
}
