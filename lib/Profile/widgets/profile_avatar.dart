import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;

  const ProfileAvatar({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _showAvatarChangeDialog(context),
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _getUserStream(),
          builder: _buildAvatarImage,
        ),
      ),
    );
  }

  Stream<DocumentSnapshot> _getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots();
  }

  Widget _buildAvatarImage(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (!snapshot.hasData)
      return const Center(child: CircularProgressIndicator());

    int? avatarIndex = snapshot.data?['avatarIndex'];
    return FittedBox(
        child: Image.asset('assets/images/avatar${avatarIndex}.png'));
  }

  Future<void> _showAvatarChangeDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Avatar?'),
        content: const Text('Do you want to change your avatar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushNamed(context, '/avatars');
    }
  }
}
