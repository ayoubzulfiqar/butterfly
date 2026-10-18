class PublicIpInfo {
  final String ip;
  final String? country;
  final String? city;
  final String? region;
  final String? isp;
  final String? asn;
  final double? latitude;
  final double? longitude;
  final String? timezone;

  const PublicIpInfo({
    required this.ip,
    this.country,
    this.city,
    this.region,
    this.isp,
    this.asn,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  factory PublicIpInfo.fromJson(Map<String, dynamic> json) {
    final ip = json['ip'] as String? ?? '';
    final loc = json['location'] as Map<String, dynamic>?;
    final asInfo = json['as'] as Map<String, dynamic>?;

    final country = loc?['country_name'] as String? ??
        loc?['country'] as String? ??
        json['country'] as String?;
    final city = loc?['city'] as String? ?? json['city'] as String?;
    final region = loc?['region_name'] as String? ??
        loc?['region'] as String? ??
        json['region'] as String?;

    final asnNum = asInfo?['number'];
    final asn = asnNum != null ? 'AS$asnNum' : json['asn'] as String?;
    final isp = asInfo?['name'] as String? ??
        json['isp'] as String? ??
        json['org'] as String?;

    final lat = (loc?['latitude'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble();
    final lon = (loc?['longitude'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        (json['lon'] as num?)?.toDouble();

    final tzMap = loc?['timezone'] as Map<String, dynamic>?;
    final timezone = tzMap?['name'] as String? ?? json['timezone'] as String?;

    return PublicIpInfo(
      ip: ip,
      country: country,
      city: city,
      region: region,
      isp: isp,
      asn: asn,
      latitude: lat,
      longitude: lon,
      timezone: timezone,
    );
  }
}
