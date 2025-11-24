// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsProvider _$DnsProviderFromJson(Map<String, dynamic> json) => DnsProvider(
  name: json['name'] as String,
  description: json['description'] as String,
  features: (json['features'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  ipv4: (json['ipv4'] as List<dynamic>).map((e) => e as String).toList(),
  ipv6: (json['ipv6'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$DnsProviderToJson(DnsProvider instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'features': instance.features,
      'ipv4': instance.ipv4,
      'ipv6': instance.ipv6,
    };
