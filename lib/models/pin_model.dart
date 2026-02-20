class Pin {
  final String pinId;
  final String gridId;
  final DateTime createdAt;
  final String? details;
  final String? note;
  final double latitude;
  final double longitude;
  final String? imageBase64;
  final int timer;
  final String? createdBy;
  Pin({
    required this.pinId,
    required this.gridId,
    required this.createdAt,
    this.details,
    this.note,
    required this.latitude,
    required this.longitude,
    this.imageBase64,
    required this.timer,
    this.createdBy,
  });

  factory Pin.fromJson(Map<String, dynamic> json) {
    final pinId = json['pinId']?.toString() ?? '';
    final gridId = json['gridId']?.toString() ?? '';
    final createdAtRaw = json['createdAt']?.toString();
    return Pin(
      pinId: pinId,
      gridId: gridId,
      createdAt: createdAtRaw != null
          ? DateTime.parse(createdAtRaw)
          : DateTime.now(),
      details: json['details']?.toString(),
      note: json['note']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageBase64: json['imageBase64']?.toString(),
      timer: (json['timer'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
      return {
        'pinId': pinId,
        'gridId': gridId,
        'createdAt': createdAt.toIso8601String(),
        'details': details,
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'imageBase64': imageBase64,
        'timer': timer,
        'createdBy': createdBy,
      };
  }

  Pin copyWith({
    String? pinId,
    String? gridId,
    DateTime? createdAt,
    String? details,
    String? note,
    double? latitude,
    double? longitude,
    String? imageBase64,
    int? timer,
    String? createdBy,
  }) {
    return Pin(
      pinId: pinId ?? this.pinId,
      gridId: gridId ?? this.gridId,
      createdAt: createdAt ?? this.createdAt,
      details: details ?? this.details,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageBase64: imageBase64 ?? this.imageBase64,
      timer: timer ?? this.timer,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
