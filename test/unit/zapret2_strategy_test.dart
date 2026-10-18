import 'package:flutter_test/flutter_test.dart';
import 'package:butterfly/domain/entities/zapret2_strategy.dart';

void main() {
  group('Zapret2Strategy and Catalog Tests', () {
    test('standard presets contain expected Ghostline strategies', () {
      expect(Zapret2Strategies.presets.length, equals(4));

      final light = Zapret2Strategies.light;
      expect(light.id, equals('z-split'));
      expect(light.profile, equals(Zapret2Profile.light));
      expect(light.tcpArgs, contains('--lua-desync=multisplit:pos=1,midsld'));
      expect(light.quicArgs, isEmpty);

      final medium = Zapret2Strategies.medium;
      expect(medium.id, equals('z-disorder'));
      expect(medium.profile, equals(Zapret2Profile.medium));
      expect(medium.tcpArgs, contains('--lua-desync=multidisorder:pos=1,midsld'));

      final strong = Zapret2Strategies.strong;
      expect(strong.id, equals('z-fake'));
      expect(strong.profile, equals(Zapret2Profile.strong));
      expect(strong.tcpArgs, anyElement(contains('fake_default_tls:badsum')));
      expect(strong.quicArgs, anyElement(contains('fake_default_quic:repeats=6')));

      final extreme = Zapret2Strategies.extreme;
      expect(extreme.id, equals('z-fake-ttl'));
      expect(extreme.profile, equals(Zapret2Profile.extreme));
      expect(extreme.tcpArgs, anyElement(contains('ip_autottl=-2,3-20')));
      expect(extreme.quicArgs, anyElement(contains('fake_default_quic:repeats=11')));
    });

    test('custom strategy constructs correctly with custom profile', () {
      final custom = Zapret2Strategies.custom(
        tcpArgs: ['--dpi-desync=fake,split2', '--dpi-desync-ttl=2'],
        quicArgs: ['--dpi-desync=fake'],
      );

      expect(custom.id, equals('custom'));
      expect(custom.profile, equals(Zapret2Profile.custom));
      expect(custom.tcpArgs.length, equals(2));
      expect(custom.quicArgs.length, equals(1));
    });

    test('strategy lookup by ID or Profile returns correct preset', () {
      expect(Zapret2Strategies.fromId('z-fake'), equals(Zapret2Strategies.strong));
      expect(Zapret2Strategies.fromProfile(Zapret2Profile.extreme), equals(Zapret2Strategies.extreme));
      expect(Zapret2Strategies.fromId('nonexistent'), equals(Zapret2Strategies.strong)); // safe default
    });
  });
}
