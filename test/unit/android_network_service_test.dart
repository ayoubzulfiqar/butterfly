import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/data/services/android_network_service.dart';
import 'package:butterfly/data/services/platform_service_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('butterfly/vpn');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late AndroidNetworkService service;
  late List<MethodCall> methodCalls;
  String mockTransport = 'Wi-Fi';
  bool mockVpnRunning = true;
  List<String> mockDnsServers = ['1.1.1.1', '1.0.0.1'];
  bool shouldThrowOnStartVpn = false;

  setUp(() {
    methodCalls = [];
    mockTransport = 'Wi-Fi';
    mockVpnRunning = true;
    mockDnsServers = ['1.1.1.1', '1.0.0.1'];
    shouldThrowOnStartVpn = false;

    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCalls.add(call);
      switch (call.method) {
        case 'getNetworkTransport':
          return mockTransport;
        case 'getVpnStatus':
          return {
            'isRunning': mockVpnRunning,
            'dnsServers': mockDnsServers,
          };
        case 'startVpn':
          if (shouldThrowOnStartVpn) {
            throw PlatformException(
              code: 'VPN_PERMISSION_DENIED',
              message: 'User denied VPN permission',
            );
          }
          return true;
        case 'stopVpn':
          return true;
        default:
          return null;
      }
    });

    service = AndroidNetworkService();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('AndroidNetworkService Tests', () {
    test('isAdministrator always returns true on Android', () async {
      final isAdmin = await service.isAdministrator();
      expect(isAdmin, isTrue);
    });

    test('getAdapters returns NetworkAdapter with active transport name and DNS servers', () async {
      final adapters = await service.getAdapters();
      expect(adapters, hasLength(1));

      final adapter = adapters.first;
      expect(adapter.name, equals('Wi-Fi'));
      expect(adapter.isUp, isTrue);
      expect(adapter.dnsServers, equals(['1.1.1.1', '1.0.0.1']));
      expect(adapter.hasDnsConfigured, isTrue);
      expect(adapter.interfaceDescription, contains('Wi-Fi'));
    });

    test('getAdapters handles Cellular transport and empty DNS gracefully', () async {
      mockTransport = 'Cellular';
      mockVpnRunning = false;
      mockDnsServers = [];

      final adapters = await service.getAdapters();
      expect(adapters, hasLength(1));

      final adapter = adapters.first;
      expect(adapter.name, equals('Cellular'));
      expect(adapter.isUp, isTrue);
      expect(adapter.dnsServers, isEmpty);
      expect(adapter.isDhcp, isTrue);
    });

    test('getCurrentDns returns list of DNS servers from VPN status', () async {
      final dns = await service.getCurrentDns('Wi-Fi');
      expect(dns, equals(['1.1.1.1', '1.0.0.1']));
      expect(methodCalls.any((call) => call.method == 'getVpnStatus'), isTrue);
    });

    test('setDns invokes startVpn with primary and secondary IPv4 servers', () async {
      await service.setDns(
        'Wi-Fi',
        ['1.1.1.1', '1.0.0.1'],
        [],
      );

      final startCall = methodCalls.firstWhere((call) => call.method == 'startVpn');
      expect(startCall.arguments, isA<Map>());
      final args = Map<String, dynamic>.from(startCall.arguments as Map);
      expect(args['primary'], equals('1.1.1.1'));
      expect(args['secondary'], equals('1.0.0.1'));
    });

    test('setDns handles single primary DNS without secondary', () async {
      await service.setDns(
        'Cellular',
        ['9.9.9.9'],
        [],
      );

      final startCall = methodCalls.firstWhere((call) => call.method == 'startVpn');
      final args = Map<String, dynamic>.from(startCall.arguments as Map);
      expect(args['primary'], equals('9.9.9.9'));
      expect(args['secondary'], isNull);
    });

    test('restoreDns invokes stopVpn on channel', () async {
      await service.restoreDns('Wi-Fi');

      expect(methodCalls.any((call) => call.method == 'stopVpn'), isTrue);
    });

    test('flushDnsCache completes without error', () async {
      await expectLater(service.flushDnsCache(), completes);
    });

    test('surfaces platform exception when VPN permission is denied', () async {
      shouldThrowOnStartVpn = true;

      expect(
        () => service.setDns('Wi-Fi', ['1.1.1.1'], []),
        throwsA(isA<PlatformException>()),
      );
    });

    test('allows custom MethodChannel injection via constructor', () async {
      const customChannel = MethodChannel('custom/vpn');
      final customService = AndroidNetworkService(channel: customChannel);
      expect(customService.channel, equals(customChannel));
    });

    test('getAdapters returns fallback adapter if channel call fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Channel failed');
      });

      final adapters = await service.getAdapters();
      expect(adapters, hasLength(1));
      expect(adapters.first.name, equals('Wi-Fi'));
      expect(adapters.first.dnsServers, isEmpty);
    });

    test('getCurrentDns returns empty list if channel call fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Channel failed');
      });

      final dns = await service.getCurrentDns('Wi-Fi');
      expect(dns, isEmpty);
    });

    test('pingHost returns null when unreachable or times out', () async {
      final latency = await service.pingHost(
        '192.0.2.1', // TEST-NET-1 (non-routable)
        timeout: const Duration(milliseconds: 50),
      );
      expect(latency, isNull);
    });
  });

  group('PlatformServiceFactory Android Dispatch', () {
    test('creates AndroidNetworkService when isAndroid is true', () {
      final service = PlatformServiceFactory.createNetworkService(
        isAndroid: true,
        isWindows: false,
        isLinux: false,
      );
      expect(service, isA<AndroidNetworkService>());
    });

    test('creates AndroidNetworkService with only isAndroid: true without specifying others', () {
      final service = PlatformServiceFactory.createNetworkService(
        isAndroid: true,
      );
      expect(service, isA<AndroidNetworkService>());
    });

    test('creates WindowsNetworkService when isWindows is true', () {
      final service = PlatformServiceFactory.createNetworkService(
        isAndroid: false,
        isWindows: true,
        isLinux: false,
      );
      expect(service.runtimeType.toString(), equals('WindowsNetworkService'));
    });

    test('creates LinuxNetworkService when isLinux is true', () {
      final service = PlatformServiceFactory.createNetworkService(
        isAndroid: false,
        isWindows: false,
        isLinux: true,
      );
      expect(service.runtimeType.toString(), equals('LinuxNetworkService'));
    });

    test('creates MockNetworkService when all platforms are false', () {
      final service = PlatformServiceFactory.createNetworkService(
        isAndroid: false,
        isWindows: false,
        isLinux: false,
      );
      expect(service.runtimeType.toString(), equals('MockNetworkService'));
    });
  });
}

