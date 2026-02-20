import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_status_message.dart';
import '../models/grid_model.dart';
import '../models/user_model.dart';

class UserFetchException implements Exception {
  final String message;
  UserFetchException(http.Response response)
      : message =
            'UserFetchException: ${response.statusCode} - ${response.statusMessage}';

  @override
  String toString() => message;
}

class UserController {
  Future<List<User>> fetchAllUsers() async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/users/admin/all"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return List<User>.from(data.map((userJson) => User.fromJson(userJson)));
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<User?> fetchUserById(String userId) async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/users/$userId"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<User?> addUser(User user) async {
    print("Adding user: ${user.toJson()}");
    return await http.post(
      Uri.parse("https://kindmap.onrender.com/api/v1/users/add"),
      body: jsonEncode(user.toJson()),
      headers: {
        'Content-Type': 'application/json', // This is critical
        'Accept': 'application/json',
      },
    ).then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("user added: $data");
        return User.fromJson(data);
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<bool> changeUserName(String userId, String userName) async {
    return await http
        .put(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/changename?newName=$userName"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    });
  }

  Future modifyUserDetails(
    String userId, {
    String? name,
    String? email,
    int? avatarIndex,
    int? helped,
    DateTime? joinedDate,
    String? token,
    List<String>? subscribedGridIds,
  }) async {
    final Map<String, dynamic> details = {};
    if (name != null) details['name'] = name;
    if (email != null) details['email'] = email;
    if (avatarIndex != null) details['avatarIndex'] = avatarIndex;
    if (helped != null) details['helped'] = helped;
    if (joinedDate != null) {
      details['joinedDate'] = joinedDate.toIso8601String();
    }
    if (token != null) details['token'] = token;
    if (subscribedGridIds != null) {
      details['subscribedGridIds'] = subscribedGridIds;
    }

    return await http
        .put(
            Uri.parse(
                "https://kindmap.onrender.com/api/v1/users/$userId/modify"),
            body: jsonEncode(details))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<List<Grid>> fetchSubscribedGrids(String userId) async {
    return await http
        .get(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/subscriptions"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return List<Grid>.from(data.map((gridJson) => Grid.fromJson(gridJson)));
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<bool> subscribeToGrid(String userId, String gridId) async {
    return await http
        .post(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/subscriptions/$gridId"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    });
  }

  Future<bool> unsubscribeFromGrid(String userId, String gridId) async {
    return await http
        .delete(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/subscriptions/$gridId"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    });
  }

  Future<int> getAvatarIndex(String userId) async {
    return await http
        .get(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/avatar"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['avatarIndex'];
      } else {
        return 1;
      }
    });
  }

  Future<bool> changeUserAvatar(String userId, int avatarIndex) async {
    return await http
        .put(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/avatar?avatarIndex=$avatarIndex"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    });
  }

  Future<int> getUserHelped(String userId) async {
    return await http
        .get(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/helped"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return 0;
      }
    });
  }

  Future<int> addHelped(String userId) async {
    return await http
        .put(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/helped/increment"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return 0;
      }
    });
  }

  Future<int> updateHelped(String userId, int newNumber) async {
    return await http
        .put(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/helped?newNumber=$newNumber"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return 0;
      }
    });
  }

  Future<String> getFCMToken(String userId) async {
    return await http
        .get(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/token"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw UserFetchException(response);
      }
    });
  }

  Future<String> updateFCMToken(String userId, String token) async {
    return await http
        .put(Uri.parse(
            "https://kindmap.onrender.com/api/v1/users/$userId/token?token=$token"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw UserFetchException(response);
      }
    });
  }
}
