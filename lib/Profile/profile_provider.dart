import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> updateName(String newName) async {
    if (newName.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'name': newName});

      _error = null;
    } catch (e) {
      _error = 'Failed to update name: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(int index) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'avatarIndex': index});

      _error = null;
    } catch (e) {
      _error = 'Failed to update avatar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
