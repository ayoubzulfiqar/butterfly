/// Protection profile presets corresponding to Ghostline's 4-tier model.
enum Zapret2Profile {
  /// Multisplit at pos 1 + midsld (Light)
  light,

  /// Multidisorder at pos 1 + midsld (Medium)
  medium,

  /// Fake TLS ClientHello + multidisorder + QUIC packet repeat desync (Strong)
  strong,

  /// Dynamic autottl fake packets + faked disorder (Extreme)
  extreme,

  /// User-defined arguments
  custom,
}

/// Model representing a zapret2 desynchronization strategy.
class Zapret2Strategy {
  final String id;
  final String name;
  final String description;
  final List<String> tcpArgs;
  final List<String> quicArgs;
  final Zapret2Profile profile;

  const Zapret2Strategy({
    required this.id,
    required this.name,
    required this.description,
    required this.tcpArgs,
    required this.quicArgs,
    required this.profile,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Zapret2Strategy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          profile == other.profile;

  @override
  int get hashCode => id.hashCode ^ profile.hashCode;
}

/// Standard verified zapret2 strategies ported from Ghostline.
class Zapret2Strategies {
  static const light = Zapret2Strategy(
    id: 'z-split',
    name: 'Light',
    description: 'Multisplit at position 1 and middle SLD',
    tcpArgs: ['--lua-desync=multisplit:pos=1,midsld'],
    quicArgs: [],
    profile: Zapret2Profile.light,
  );

  static const medium = Zapret2Strategy(
    id: 'z-disorder',
    name: 'Medium',
    description: 'Out-of-order packet segment delivery',
    tcpArgs: ['--lua-desync=multidisorder:pos=1,midsld'],
    quicArgs: [],
    profile: Zapret2Profile.medium,
  );

  static const strong = Zapret2Strategy(
    id: 'z-fake',
    name: 'Strong',
    description: 'Fake TLS ClientHello + multidisorder + QUIC repeat desync',
    tcpArgs: [
      '--lua-desync=fake:blob=fake_default_tls:badsum',
      '--lua-desync=multidisorder:pos=1,midsld',
    ],
    quicArgs: [
      '--lua-desync=fake:blob=fake_default_quic:repeats=6',
    ],
    profile: Zapret2Profile.strong,
  );

  static const extreme = Zapret2Strategy(
    id: 'z-fake-ttl',
    name: 'Extreme',
    description: 'Dynamic autottl fake packets with faked disorder',
    tcpArgs: [
      '--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20',
      '--lua-desync=fakeddisorder:pos=1,midsld',
    ],
    quicArgs: [
      '--lua-desync=fake:blob=fake_default_quic:repeats=11',
    ],
    profile: Zapret2Profile.extreme,
  );

  static Zapret2Strategy custom({
    required List<String> tcpArgs,
    List<String> quicArgs = const [],
    String name = 'Custom',
    String description = 'User-configured desynchronization parameters',
  }) {
    return Zapret2Strategy(
      id: 'custom',
      name: name,
      description: description,
      tcpArgs: tcpArgs,
      quicArgs: quicArgs,
      profile: Zapret2Profile.custom,
    );
  }

  static const List<Zapret2Strategy> presets = [
    light,
    medium,
    strong,
    extreme,
  ];

  static Zapret2Strategy fromId(String id) {
    for (final s in presets) {
      if (s.id == id) return s;
    }
    return strong;
  }

  static Zapret2Strategy fromProfile(Zapret2Profile profile) {
    for (final s in presets) {
      if (s.profile == profile) return s;
    }
    return strong;
  }
}
