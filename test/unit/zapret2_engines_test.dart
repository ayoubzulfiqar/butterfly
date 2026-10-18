import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/zapret2_strategy.dart';
import 'package:butterfly/domain/services/dpi_engine.dart';
import 'package:butterfly/data/services/zapret2_linux_engine.dart';
import 'package:butterfly/data/services/zapret2_windows_engine.dart';
import 'package:butterfly/data/services/goodbyedpi_engine.dart';

void main() {
  group('Zapret2LinuxEngine Argument and nftables Generation', () {
    late Zapret2LinuxEngine engine;

    setUp(() {
      engine = Zapret2LinuxEngine();
    });

    test('metadata properties match Linux requirements', () {
      expect(engine.id, equals('zapret2'));
      expect(engine.name, contains('zapret2'));
      expect(engine.executableName, equals('nfqws2'));
    });

    test('buildArgs generates queue, fwmark, user and strategy flags', () {
      final config = DpiEngineConfig(
        strategy: Zapret2Strategies.strong,
        enableQuic: true,
      );

      final args = engine.buildArgs(config);

      expect(args, contains('--qnum=510'));
      expect(args, contains('--fwmark=0x10000'));
      expect(args, contains('--user=daemon'));
      expect(args, contains('--filter-tcp=80,443'));
      // TCP strategy args
      expect(args, contains('--lua-desync=fake:blob=fake_default_tls:badsum'));
      expect(args, contains('--lua-desync=multidisorder:pos=1,midsld'));
      // QUIC profile
      expect(args, contains('--new'));
      expect(args, contains('--filter-udp=443'));
      expect(args, contains('--filter-l7=quic'));
      expect(args, contains('--lua-desync=fake:blob=fake_default_quic:repeats=6'));
    });

    test('buildArgs omits QUIC profile if enableQuic is false', () {
      final config = DpiEngineConfig(
        strategy: Zapret2Strategies.strong,
        enableQuic: false,
      );

      final args = engine.buildArgs(config);
      expect(args, isNot(contains('--filter-l7=quic')));
    });

    test('buildNftablesScript generates valid bypass table and queue rules', () {
      final script = engine.buildNftablesScript(queueNum: 510, fwmark: 0x10000);

      expect(script, contains('table inet butterfly_dpi'));
      expect(script, contains('queue num 510 bypass'));
      expect(script, contains('oifname "lo" accept'));
      expect(script, contains('mark & 0x10000 != 0'));
    });
  });

  group('Zapret2WindowsEngine Argument Generation', () {
    late Zapret2WindowsEngine engine;

    setUp(() {
      engine = Zapret2WindowsEngine();
    });

    test('metadata properties match Windows requirements', () {
      expect(engine.id, equals('zapret2'));
      expect(engine.executableName, equals('winws2.exe'));
    });

    test('buildArgs generates WinDivert interception filters and profiles', () {
      final config = DpiEngineConfig(
        strategy: Zapret2Strategies.strong,
        enableQuic: true,
      );

      final args = engine.buildArgs(config);

      expect(args, contains('--wf-tcp-out=80,443'));
      expect(args, contains('--wf-udp-out=443'));
      expect(args, contains('--wf-dup-check=1'));
      expect(args, contains('--filter-tcp=80,443'));
      expect(args, contains('--new'));
      expect(args, contains('--filter-l7=quic'));
    });
  });

  group('GoodbyeDpiEngine Legacy Fallback', () {
    late GoodbyeDpiEngine engine;

    setUp(() {
      engine = GoodbyeDpiEngine();
    });

    test('metadata properties match GoodbyeDPI', () {
      expect(engine.id, equals('goodbyedpi'));
      expect(engine.executableName, equals('goodbyedpi.exe'));
    });

    test('buildArgs translates custom or preset flags correctly', () {
      final config = DpiEngineConfig(
        strategy: Zapret2Strategies.light,
        customArgs: ['-1', '--fake-gen=1'],
      );

      final args = engine.buildArgs(config);
      expect(args, contains('-1'));
      expect(args, contains('--fake-gen=1'));
    });
  });
}
