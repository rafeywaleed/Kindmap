import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_status_message.dart';
import '../models/pin_model.dart';

class PinFetchException implements Exception {
  final String message;
  PinFetchException(http.Response response)
      : message =
            'PinFetchException: ${response.statusCode} - ${response.statusMessage}';

  @override
  String toString() => message;
}

class PinController {
  Future<List<Pin>> fetchAllPins() async {
    final response = await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/pins/all"));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Pin.fromJson(json)).toList();
    } else {
      throw PinFetchException(response);
    }
  }

  Stream<List<Pin>> streamAllPins() async* {
    while (true) {
      final response = await http
          .get(Uri.parse("https://kindmap.onrender.com/api/v1/pins/all"));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = jsonDecode(response.body);
        yield data.map((json) => Pin.fromJson(json)).toList();
      } else {
        throw PinFetchException(response);
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<Pin?> fetchPinById(String pinId) async {
    return await http
        .get(Uri.parse("https://kindmap.onrender.com/api/v1/pins/$pinId"))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Pin.fromJson(data);
      } else {
        throw PinFetchException(response);
      }
    });
  }

  Stream<Pin?> streamPinById(String pinId) async* {
    while (true) {
      final response = await http
          .get(Uri.parse("https://kindmap.onrender.com/api/v1/pins/$pinId"));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        yield Pin.fromJson(data);
      } else {
        throw PinFetchException(response);
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future addPin(Pin pin) async {
    final payload = pin.toJson();
    debugPrint('addPin: payload=$payload');

    return await http.post(
      Uri.parse("https://kindmap.onrender.com/api/v1/pins/add"),
      body: jsonEncode(payload),
      headers: {'Content-Type': 'application/json'},
    ).then((response) {
      print(
        'addPin: status=${response.statusCode}, body=${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw PinFetchException(response);
      }
    }).catchError((error) {
      debugPrint('addPin: error=$error');
      throw error;
    });
  }

  Future deletePin(String pinID) async {
    return await http
        .delete(
            Uri.parse("https://kindmap.onrender.com/api/v1/pins/delete/$pinID"))
        .timeout(const Duration(seconds: 20))
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw PinFetchException(response);
      }
    });
  }
}
