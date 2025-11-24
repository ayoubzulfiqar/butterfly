import 'package:flutter/material.dart';
import '../../data/repositories/dns_provider_repository.dart';
import '../../data/repositories/dns_service.dart';
import '../../domain/usecases/get_dns_providers_usecase.dart';
import '../../domain/usecases/change_dns_usecase.dart';
import '../../domain/usecases/restore_dns_usecase.dart';
import '../../domain/usecases/get_current_dns_usecase.dart';
import '../../domain/usecases/get_adapters_usecase.dart';
import '../../domain/usecases/start_dpi_bypass_usecase.dart';
import '../../domain/usecases/stop_dpi_bypass_usecase.dart';
import '../../data/models/dns_provider.dart';
import '../../core/utils/logger.dart';

/// ViewModel for DNS Changer screen.
class DnsChangerViewModel extends ChangeNotifier {
  final DnsProviderRepository dnsProviderRepository;
  final DnsService dnsService;

  late final GetDnsProvidersUseCase getProvidersUseCase;
  late final ChangeDnsUseCase changeDnsUseCase;
  late final RestoreDnsUseCase restoreDnsUseCase;
  late final GetCurrentDnsUseCase getCurrentDnsUseCase;
  late final GetAdaptersUseCase getAdaptersUseCase;
  late final StartDpiBypassUseCase startDpiBypassUseCase;
  late final StopDpiBypassUseCase stopDpiBypassUseCase;

  List<DnsProvider> _providers = [];
  List<String> _adapters = [];
  String _selectedAdapter = '';
  String _currentDns = '';
  bool _isLoading = false;
  String _message = '';
  bool _isDpiBypassRunning = false;

  DnsChangerViewModel({
    required this.dnsProviderRepository,
    required this.dnsService,
  }) {
    getProvidersUseCase = GetDnsProvidersUseCase(dnsProviderRepository);
    changeDnsUseCase = ChangeDnsUseCase(dnsService);
    restoreDnsUseCase = RestoreDnsUseCase(dnsService);
    getCurrentDnsUseCase = GetCurrentDnsUseCase(dnsService);
    getAdaptersUseCase = GetAdaptersUseCase(dnsService);
    startDpiBypassUseCase = StartDpiBypassUseCase(dnsService);
    stopDpiBypassUseCase = StopDpiBypassUseCase(dnsService);
    loadData();
  }

  List<DnsProvider> get providers => _providers;
  List<String> get adapters => _adapters;
  String get selectedAdapter => _selectedAdapter;
  String get currentDns => _currentDns;
  bool get isLoading => _isLoading;
  String get message => _message;
  bool get isDpiBypassRunning => _isDpiBypassRunning;

  void loadData() {
    _providers = getProvidersUseCase.execute();
    _loadAdapters();
    notifyListeners();
  }

  Future<void> _loadAdapters() async {
    try {
      _adapters = await getAdaptersUseCase.execute();
      if (_adapters.isNotEmpty) {
        _selectedAdapter = _adapters[0];
        await _loadCurrentDns();
      }
    } catch (e) {
      _message = 'Failed to load adapters: $e';
      logger.warning(_message);
    }
    notifyListeners();
  }

  Future<void> _loadCurrentDns() async {
    if (_selectedAdapter.isEmpty) return;
    try {
      _currentDns = await getCurrentDnsUseCase.execute(_selectedAdapter);
    } catch (e) {
      _currentDns = 'Failed to get DNS: $e';
      logger.warning(_currentDns);
    }
    notifyListeners();
  }

  void selectAdapter(String adapter) {
    _selectedAdapter = adapter;
    _loadCurrentDns();
  }

  Future<void> changeDns(DnsProvider provider) async {
    if (_selectedAdapter.isEmpty) {
      _message = 'No adapter selected';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _message = '';
    notifyListeners();
    try {
      await changeDnsUseCase.execute(_selectedAdapter, provider.ipv4, provider.ipv6);
      _message = 'DNS changed to ${provider.name}';
      logger.info(_message);
      await _loadCurrentDns();
    } catch (e) {
      _message = 'Failed to change DNS: $e';
      logger.severe(_message);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> restoreDns() async {
    if (_selectedAdapter.isEmpty) {
      _message = 'No adapter selected';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _message = '';
    notifyListeners();
    try {
      await restoreDnsUseCase.execute(_selectedAdapter);
      _message = 'DNS restored to default';
      logger.info(_message);
      await _loadCurrentDns();
    } catch (e) {
      _message = 'Failed to restore DNS: $e';
      logger.severe(_message);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startDpiBypass() async {
    _isLoading = true;
    _message = '';
    notifyListeners();
    try {
      await startDpiBypassUseCase.execute();
      _isDpiBypassRunning = true;
      _message = 'DPI bypass started';
      logger.info(_message);
    } catch (e) {
      _message = 'Failed to start DPI bypass: $e';
      logger.severe(_message);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> stopDpiBypass() async {
    _isLoading = true;
    _message = '';
    notifyListeners();
    try {
      await stopDpiBypassUseCase.execute();
      _isDpiBypassRunning = false;
      _message = 'DPI bypass stopped';
      logger.info(_message);
    } catch (e) {
      _message = 'Failed to stop DPI bypass: $e';
      logger.severe(_message);
    }
    _isLoading = false;
    notifyListeners();
  }
}