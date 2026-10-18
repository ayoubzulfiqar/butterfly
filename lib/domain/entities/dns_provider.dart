/// Categories for DNS resolvers.
enum DnsCategory { all, privacy, security, gaming, family, custom }

/// Immutable model representing a DNS Provider with addresses and metadata.
class DnsProvider {
  final String id;
  final String name;
  final String description;
  final DnsCategory category;
  final List<String> features;
  final List<String> ipv4;
  final List<String> ipv6;
  final int? latencyMs;
  final bool isCustom;

  const DnsProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.features,
    required this.ipv4,
    required this.ipv6,
    this.latencyMs,
    this.isCustom = false,
  });

  DnsProvider copyWith({
    String? id,
    String? name,
    String? description,
    DnsCategory? category,
    List<String>? features,
    List<String>? ipv4,
    List<String>? ipv6,
    int? latencyMs,
    bool? isCustom,
  }) {
    return DnsProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      features: features ?? this.features,
      ipv4: ipv4 ?? this.ipv4,
      ipv6: ipv6 ?? this.ipv6,
      latencyMs: latencyMs ?? this.latencyMs,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'features': features,
      'ipv4': ipv4,
      'ipv6': ipv6,
      'isCustom': isCustom,
    };
  }

  factory DnsProvider.fromJson(Map<String, dynamic> json) {
    return DnsProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: DnsCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DnsCategory.custom,
      ),
      features: List<String>.from(json['features'] as List? ?? []),
      ipv4: List<String>.from(json['ipv4'] as List? ?? []),
      ipv6: List<String>.from(json['ipv6'] as List? ?? []),
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}
