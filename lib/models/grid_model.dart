import 'pin_model.dart';

class Grid {
  final String gridId;
  final List<Pin> pins;
  final List<String> users;
  Grid({
    required this.gridId,
    required this.pins,
    required this.users,
  });

  factory Grid.fromJson(Map<String, dynamic> json) {
    return Grid(
      gridId: json['gridId'],
      pins: (json['pins'] as List<dynamic>)
          .map((pinJson) => Pin.fromJson(pinJson))
          .toList(),
      users: List<String>.from(json['users'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gridId': gridId,
      'pins': pins.map((pin) => pin.toJson()).toList(),
      'users': users,
    };
  }

  Grid copyWith({
    String? gridId,
    List<Pin>? pins,
    List<String>? users,
  }) {
    return Grid(
      gridId: gridId ?? this.gridId,
      pins: pins ?? this.pins,
      users: users ?? this.users,
    );
  }
}
