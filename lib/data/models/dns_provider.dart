import 'package:json_annotation/json_annotation.dart';

part 'dns_provider.g.dart';

/// Model representing a DNS provider with its details.
@JsonSerializable()
class DnsProvider {
  final String name;
  final String description;
  final List<String> features;
  final List<String> ipv4;
  final List<String> ipv6;

  const DnsProvider({
    required this.name,
    required this.description,
    required this.features,
    required this.ipv4,
    required this.ipv6,
  });

  factory DnsProvider.fromJson(Map<String, dynamic> json) => _$DnsProviderFromJson(json);
  Map<String, dynamic> toJson() => _$DnsProviderToJson(this);
}