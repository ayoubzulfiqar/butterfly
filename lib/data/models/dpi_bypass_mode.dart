/// Model for DPI bypass modes supported by GoodbyeDPI
class DpiBypassMode {
  final String name;
  final String description;
  final List<String> args;

  const DpiBypassMode({
    required this.name,
    required this.description,
    required this.args,
  });
}

/// Available DPI bypass modes
class DpiBypassModes {
  static const List<DpiBypassMode> all = [
    DpiBypassMode(
      name: 'Basic Bypass',
      description: 'Simple bypass mode for most websites',
      args: ['-1'],
    ),
    DpiBypassMode(
      name: 'Standard Bypass',
      description: 'Standard bypass with fake packet generation',
      args: ['-1', '--fake-gen=1'],
    ),
    DpiBypassMode(
      name: 'Advanced Bypass',
      description: 'Advanced bypass with custom fake packets',
      args: ['-1', '--fake-gen=1', '--fake-from-hex=1603010200010001ffffff000100000020000a00080006001700180019000b00020100000d00120010040105010201040305030203040206010202040300050004010000000012000000170000'],
    ),
    DpiBypassMode(
      name: 'Russia Blacklist',
      description: 'Bypass with Russia-specific blacklist',
      args: ['-9', '--blacklist', 'russia-blacklist.txt', '--blacklist', 'russia-youtube.txt'],
    ),
    DpiBypassMode(
      name: 'Russia DNS Redirect',
      description: 'Russia bypass with DNS redirection',
      args: ['-9', '--dns-addr', '77.88.8.8', '--dns-port', '1253', '--dnsv6-addr', '2a02:6b8::feed:0ff', '--dnsv6-port', '1253', '--blacklist', 'russia-blacklist.txt', '--blacklist', 'russia-youtube.txt'],
    ),
    DpiBypassMode(
      name: 'Universal Bypass',
      description: 'Universal bypass for any country blocking',
      args: ['-9'],
    ),
    DpiBypassMode(
      name: 'YouTube Focus',
      description: 'Optimized for YouTube unblocking',
      args: ['-9', '--blacklist', 'russia-youtube.txt'],
    ),
  ];
}