import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/cyber_theme.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/logger.dart';
import 'data/repositories/dns_provider_repository_impl.dart';
import 'data/services/cloudflare_scanner_service_impl.dart';
import 'data/services/dns_benchmark_service_impl.dart';
import 'data/services/dns_safety_net_service_impl.dart';
import 'data/services/platform_service_factory.dart';
import 'data/services/system_tools_service_impl.dart';
import 'data/services/tls_fragmenter_service_impl.dart';
import 'domain/repositories/i_dns_provider_repository.dart';
import 'domain/services/cloudflare_scanner_service.dart';
import 'domain/services/dns_safety_net_service.dart';
import 'domain/services/i_dns_benchmark_service.dart';
import 'domain/services/i_dpi_service.dart';
import 'domain/services/i_network_service.dart';
import 'domain/services/i_system_tools_service.dart';
import 'domain/services/tls_fragmenter.dart';
import 'presentation/viewmodels/diagnostics_viewmodel.dart';
import 'presentation/viewmodels/dpi_viewmodel.dart';
import 'presentation/viewmodels/navigation_viewmodel.dart';
import 'presentation/viewmodels/network_dns_viewmodel.dart';
import 'presentation/viewmodels/tools_viewmodel.dart';
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
  final ISystemToolsService? toolsService;
  final IDnsBenchmarkService? benchmarkService;
  final IDnsSafetyNetService? safetyNetService;
  final ICloudflareScannerService? cfScannerService;
  final ITlsFragmenterService? tlsFragmenterService;

  const ButterflyApp({
    super.key,
    this.networkService,
    this.dpiService,
    this.repository,
    this.toolsService,
    this.benchmarkService,
    this.safetyNetService,
    this.cfScannerService,
    this.tlsFragmenterService,
  });

  @override
  State<ButterflyApp> createState() => _ButterflyAppState();
}

class _ButterflyAppState extends State<ButterflyApp> {
  late final INetworkService _networkService;
  late final IDpiService _dpiService;
  late final IDnsProviderRepository _repository;
  late final ISystemToolsService _toolsService;
  late final IDnsBenchmarkService _benchmarkService;
  late final IDnsSafetyNetService _safetyNetService;
  late final ICloudflareScannerService _cfScannerService;
  late final ITlsFragmenterService _tlsFragmenterService;

  @override
  void initState() {
    super.initState();
    _networkService =
        widget.networkService ?? PlatformServiceFactory.createNetworkService();

    _dpiService = widget.dpiService ?? PlatformServiceFactory.createDpiService();

    _repository = widget.repository ?? DnsProviderRepositoryImpl();
    _toolsService = widget.toolsService ?? SystemToolsServiceImpl();
    _benchmarkService = widget.benchmarkService ?? DnsBenchmarkServiceImpl();
    _safetyNetService = widget.safetyNetService ?? DnsSafetyNetServiceImpl();
    _cfScannerService = widget.cfScannerService ?? CloudflareScannerServiceImpl();
    _tlsFragmenterService = widget.tlsFragmenterService ?? TlsFragmenterServiceImpl();

    // Asynchronously synchronize remote provider catalog in the background
    _repository.syncRemoteCatalog().catchError((error) {
      appLogger.warning('ButterflyApp', 'Remote catalog sync fallback: $error');
      return false;
    });
  }

  @override
  void dispose() {
    _dpiService.dispose();
    _tlsFragmenterService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ITlsFragmenterService>.value(value: _tlsFragmenterService),
        ChangeNotifierProvider<NavigationViewModel>(
          create: (_) => NavigationViewModel(),
        ),
        ChangeNotifierProvider<NetworkDnsViewModel>(
          create: (_) => NetworkDnsViewModel(
            networkService: _networkService,
            repository: _repository,
            benchmarkService: _benchmarkService,
            safetyNetService: _safetyNetService,
          )..loadInitialData(),
        ),
        ChangeNotifierProvider<DpiViewModel>(
          create: (_) => DpiViewModel(dpiService: _dpiService),
        ),
        ChangeNotifierProvider<DiagnosticsViewModel>(
          create: (_) => DiagnosticsViewModel(),
        ),
        ChangeNotifierProvider<ToolsViewModel>(
          create: (_) => ToolsViewModel(
            toolsService: _toolsService,
            cfScannerService: _cfScannerService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Butterfly - Enterprise DNS Suite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fluentLight,
        darkTheme: CyberTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainShellScreen(),
      ),
    );
  }
}
