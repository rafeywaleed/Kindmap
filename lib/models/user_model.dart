class User {
  final String userId;
  final String name;
  final String email;
  final int avatarIndex;
  final int helped;
  final DateTime joinedDate;
  final String? token;
  final List<String> subscribedGridIds;
  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.avatarIndex,
    required this.helped,
    required this.joinedDate,
    required this.token,
    required this.subscribedGridIds,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
      helped: (json['helped'] as num?)?.toInt() ?? 0,
      joinedDate: json['joinedDate'] != null
          ? DateTime.parse(json['joinedDate'].toString())
          : DateTime.now(),
      token: json['token']?.toString(),
      subscribedGridIds: json['subscribedGridIds'] != null
          ? List<String>.from(json['subscribedGridIds'] as List)
          : [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'avatarIndex': avatarIndex,
      'helped': helped,
      'joinedDate': joinedDate.toIso8601String(),
      'token': token ?? '',
      'subscribedGridIds': subscribedGridIds,
    };
  }

  User copyWith({
    String? userId,
    String? name,
    String? email,
    int? avatarIndex,
    int? helped,
    DateTime? joinedDate,
    String? token,
    List<String>? subscribedGridIds,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      helped: helped ?? this.helped,
      joinedDate: joinedDate ?? this.joinedDate,
      token: token ?? this.token,
      subscribedGridIds: subscribedGridIds ?? this.subscribedGridIds,
    );
  }
}
