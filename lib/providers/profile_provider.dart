import 'package:flutter/material.dart';

import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class ProfileProvider with ChangeNotifier {
  ProfileProvider({String? userId}) : _userId = userId;

  String? _userId;
  final UserController _userController = UserController();
  User? _user;
  int? _avatarIndex;
  String? _email;
  String? _error;
  bool _isLoading = false;

  String? get userId => _userId;
  User? get user => _user;
  int? get avatarIndex => _avatarIndex;
  String? get email => _email;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void updateUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _user = null;
    _avatarIndex = null;
    _email = null;
    _error = null;
    notifyListeners();

    // Auto-load profile when userId changes
    if (userId != null && userId.isNotEmpty) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final User? user = await _userController.fetchUserById(_userId!);
      _user = user;
      _avatarIndex = user!.avatarIndex;
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateName(String newName) async {
    if (newName.isEmpty || _userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _userController.changeUserName(_userId!, newName);

      if (_user != null) {
        _user = _user!.copyWith(name: newName);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to update name: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatarIndex(int index) async {
    if (_userId == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      await _userController.changeUserAvatar(_userId!, index);

      _avatarIndex = index;
      if (_user != null) {
        _user = _user!.copyWith(avatarIndex: index);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to update avatar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
