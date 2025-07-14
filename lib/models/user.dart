import 'dart:core';

import 'package:kindmap/models/latlong.dart';

class User {
  String? id;
  String? name;
  String? email;
  String? dateJoined;
  List<String>? subscribedLocations;
  DateTime? joinedAt;
  LatLong? lastLocation;
  List<String>? pinnedPinIds;
  List<String>? servedPinIds;
  int? avatarIndex;

  User({
    this.id,
    this.name,
    this.email,
    this.dateJoined,
    this.subscribedLocations,
    this.joinedAt,
    this.lastLocation,
    this.pinnedPinIds,
    this.servedPinIds,
    this.avatarIndex,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      dateJoined: json['dateJoined'] as String?,
      subscribedLocations: (json['subscribedLocations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      joinedAt:
          json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      lastLocation: json['lastLocation'] != null
          ? LatLong.fromJson(json['lastLocation'])
          : null,
      pinnedPinIds: (json['pinnedPinIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      servedPinIds: (json['servedPinIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avatarIndex: json['avatarIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dateJoined': dateJoined,
      'subscribedLocations': subscribedLocations,
      'joinedAt': joinedAt?.toIso8601String(),
      'lastLocation': lastLocation?.toJson(),
      'pinnedPinIds': pinnedPinIds,
      'servedPinIds': servedPinIds,
      'avatarIndex': avatarIndex,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? dateJoined,
    List<String>? subscribedLocations,
    DateTime? joinedAt,
    LatLong? lastLocation,
    List<String>? pinnedPinIds,
    List<String>? servedPinIds,
    int? avatarIndex,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dateJoined: dateJoined ?? this.dateJoined,
      subscribedLocations: subscribedLocations ?? this.subscribedLocations,
      joinedAt: joinedAt ?? this.joinedAt,
      lastLocation: lastLocation ?? this.lastLocation,
      pinnedPinIds: pinnedPinIds ?? this.pinnedPinIds,
      servedPinIds: servedPinIds ?? this.servedPinIds,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }
}
