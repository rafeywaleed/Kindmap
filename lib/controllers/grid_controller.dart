import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_status_message.dart';
import '../models/grid_model.dart';
import '../models/pin_model.dart';
import '../models/user_model.dart';

class GridFetchException implements Exception {
  final String message;
  GridFetchException(http.Response response)
      : message =
            'GridFetchException: ${response.statusCode} - ${response.statusMessage}';

  @override
  String toString() => message;
}

class GridController {
  Future<List<Grid>> fetchAllGrids() async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/grids/all"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return List<Grid>.from(data.map((gridJson) => Grid.fromJson(gridJson)));
      } else {
        throw GridFetchException(response);
      }
    });
  }

  Future<Grid> fetchGridById(String gridId) async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/grids/$gridId"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Grid.fromJson(data);
      } else {
        throw GridFetchException(response);
      }
    });
  }

  Future<List<Pin>> fetchPinsByGridId(String gridId) async {
    return await http
        .get(
            Uri.parse("https://kindmap.onrender.com/api/v1/grids/$gridId/pins"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return List<Pin>.from(data.map((pinJson) => Pin.fromJson(pinJson)));
      } else {
        throw GridFetchException(response);
      }
    });
  }

  Stream<List<Pin>> streamGridPins(String gridId) async* {
    while (true) {
      final response = await http.get(
          Uri.parse("https://kindmap.onrender.com/api/v1/grids/$gridId/pins"));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = jsonDecode(response.body);
        yield data.map((json) => Pin.fromJson(json)).toList();
      } else {
        throw GridFetchException(response);
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<User>> fetchUsersByGridId(String gridId) async {
    return await http
        .get(Uri.parse(
            "https://kindmap.onrender.com/api/v1/grids/$gridId/users"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return List<User>.from(data.map((userJson) => User.fromJson(userJson)));
      } else {
        throw GridFetchException(response);
      }
    });
  }
}
