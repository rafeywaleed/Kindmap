class LatLong {
  late final double latitude;
  late final double longitude;

  LatLong({required this.latitude, required this.longitude});

  factory LatLong.fromJson(Map<String, dynamic> json) {
    return LatLong(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
