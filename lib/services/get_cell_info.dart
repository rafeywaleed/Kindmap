import 'dart:math';

Map<String, dynamic> getCellInfo(double lat, double long) {
  const double kmPerLatDegree = 111.32;
  const double cellSizeKm = 2.0;

  final deltaLatDeg = cellSizeKm / kmPerLatDegree;
  final row = (lat / deltaLatDeg).floor();

  final swLat = row * deltaLatDeg;
  final swLatRad = swLat * pi / 180;
  final deltaLongDeg = cellSizeKm / (kmPerLatDegree * cos(swLatRad));
  final col = (long / deltaLongDeg).floor();

  return {
    'row': row,
    'col': col,
    'cellId': '${row}_${col}',
    'topic': 'grid_${row}_${col}',
    'deltaLatDeg': deltaLatDeg,
    'deltaLongDeg': deltaLongDeg,
  };
}
