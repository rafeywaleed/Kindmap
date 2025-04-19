import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PasswordChangeForm extends StatefulWidget {
  const PasswordChangeForm({Key? key}) : super(key: key);

  @override
  State<PasswordChangeForm> createState() => _PasswordChangeFormState();
}

class _PasswordChangeFormState extends State<PasswordChangeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')));
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_passwordVisible,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'New Password',
              suffixIcon: IconButton(
                icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_passwordVisible,
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _changePassword,
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
