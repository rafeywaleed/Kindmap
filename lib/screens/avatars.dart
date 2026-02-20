import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../controllers/user_controller.dart";
import "../providers/profile_provider.dart";

class Avatars extends StatefulWidget {
  const Avatars({super.key});

  @override
  State<Avatars> createState() => _AvatarsState();
}

class _AvatarsState extends State<Avatars> {
  int selectedAvatarIndex = -1;
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select your Avatar: "),
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedAvatarIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selectedAvatarIndex == index
                      ? Colors.green
                      : Colors.transparent,
                  width: 5,
                ),
              ),
              child: Image.asset(
                'assets/images/avatar${index + 1}.png',
                width: size.width * 0.3,
                height: size.width * 0.3,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          uploadindex();
          Navigator.of(context).pop();
          debugPrint('Selected Avatar Index: $selectedAvatarIndex');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.check, size: 30, color: Colors.white),
      ),
    );
  }

  Future<void> uploadindex() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context
            .read<ProfileProvider>()
            .updateAvatarIndex(selectedAvatarIndex + 1);
        await UserController()
            .changeUserAvatar(user.uid, selectedAvatarIndex + 1);
      }
    } catch (e) {
      debugPrint('Error uploading avatar index: $e');
    }
  }
}
