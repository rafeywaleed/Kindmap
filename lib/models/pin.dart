import 'package:kindmap/models/latlong.dart';

class Pin {
  String? pinId;
  LatLong? location;
  String? image;
  String? description;
  String? note;
  DateTime? createdAt;
  String? createdBy;
  int? timer;

  Pin({
    this.pinId,
    this.location,
    this.image,
    this.description,
    this.note,
    this.createdAt,
    this.createdBy,
    this.timer,
  });

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(
      pinId: json['pinId'] as String?,
      location:
          json['location'] != null ? LatLong.fromJson(json['location']) : null,
      image: json['image'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      createdBy: json['createdBy'] as String?,
      timer: json['timer'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pinId': pinId,
      'location': location?.toJson(),
      'image': image,
      'description': description,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'timer': timer,
    };
  }

  Pin copyWith({
    String? pinId,
    LatLong? location,
    String? image,
    String? description,
    String? note,
    DateTime? createdAt,
    String? createdBy,
    int? timer,
  }) {
    return Pin(
      pinId: pinId ?? this.pinId,
      location: location ?? this.location,
      image: image ?? this.image,
      description: description ?? this.description,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      timer: timer ?? this.timer,
    );
  }
}
