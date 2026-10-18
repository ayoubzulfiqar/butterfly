/// Model representing a DPI bypass mode for GoodbyeDPI.
class DpiBypassMode {
  final String id;
  final String name;
  final String description;
  final List<String> args;

  const DpiBypassMode({
    required this.id,
    required this.name,
    required this.description,
    required this.args,
  });
}

/// Standard verified DPI bypass presets.
class DpiBypassModes {
  static const basic = DpiBypassMode(
    id: 'basic',
    name: 'Basic Bypass',
    description: 'Simple bypass mode for standard website blocks (-1)',
    args: ['-1'],
  );

  static const standard = DpiBypassMode(
    id: 'standard',
    name: 'Standard Bypass',
    description: 'Standard bypass with fake packet generation (-1 --fake-gen=1)',
    args: ['-1', '--fake-gen=1'],
  );

  static const advanced = DpiBypassMode(
    id: 'advanced',
    name: 'Advanced Custom Fake Packets',
    description: 'Advanced bypass with customized fake hex payload',
    args: [
      '-1',
      '--fake-gen=1',
      '--fake-from-hex=1603010200010001ffffff000100000020000a0008000600170018'
          '0019000b00020100000d00120010040105010201040305030203040206010202040'
          '300050004010000000012000000170000',
    ],
  );

  static const universal = DpiBypassMode(
    id: 'universal',
    name: 'Universal Bypass',
    description: 'Aggressive universal bypass mode for any country filtering (-9)',
    args: ['-9'],
  );

  static const youtube = DpiBypassMode(
    id: 'youtube',
    name: 'YouTube Focus',
    description: 'Optimized specifically for streaming media and YouTube',
    args: ['-9', '--blacklist', 'russia-youtube.txt'],
  );

  static const List<DpiBypassMode> all = [
    basic,
    standard,
    advanced,
    universal,
    youtube,
  ];
}
