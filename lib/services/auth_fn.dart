import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../controllers/user_controller.dart';
import '../models/user_model.dart';
// import 'package:kindmap/new_Auth/firebase_fn.dart';

// class AuthServices {
//   static signupUser(
//       String email, String password, String name, BuildContext context) async {
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
//       await FirebaseAuth.instance.currentUser!.updateEmail(email);
//       await FirestoreServices.saveUser(name, email, userCredential.user!.uid);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Registration Successful')));
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'weak-password') {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Password Provided is too weak')));
//       } else if (e.code == 'email-already-in-use') {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Email Provided already Exists')));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(e.toString())));
//     }
//   }

//   static signinUser(String email, String password, BuildContext context) async {
//     try {
//       await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);

//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('You are Logged in')));
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('No user Found with this Email')));
//       } else if (e.code == 'wrong-password') {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Password did not match')));
//       }
//     }
//   }
// }

class AuthServices {
  static Future<void> signupUser(
      String email, String password, String name, BuildContext context) async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await UserController().addUser(User(
            userId: FirebaseAuth.instance.currentUser!.uid,
            name: name,
            email: email,
            joinedDate: DateTime.now(),
            avatarIndex: 1,
            helped: 0,
            token: fcmToken ?? '',
            subscribedGridIds: []));
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
        await FirebaseAuth.instance.currentUser!.updateEmail(email);
        // await FirestoreServices.saveUser(name, email, userCredential.user!.uid);
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await UserController().addUser(User(
            userId: userCredential.user!.uid,
            name: name,
            email: email,
            joinedDate: DateTime.now(),
            avatarIndex: 1,
            helped: 0,
            token: fcmToken ?? '',
            subscribedGridIds: []));
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')));
      // Navigate to IntroScreens after successful sign-up
      Navigator.pushReplacementNamed(context, '/introScreens');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password Provided is too weak')));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email Provided already Exists')));
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await UserController().addUser(User(
            userId: userCredential.user!.uid,
            name: name,
            email: email,
            joinedDate: DateTime.now(),
            avatarIndex: 1,
            helped: 0,
            token: fcmToken ?? '',
            subscribedGridIds: []));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  static Future<void> signinUser(
      String email, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      await UserController().updateFCMToken(
          FirebaseAuth.instance.currentUser!.uid, fcmToken ?? '');

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('You are Logged in')));

      // Navigate to HomePage after successful sign-in
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user Found with this Email')));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password did not match')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  // static Future<void> signInWithGoogle() async {
  //   GoogleSignInAccount? googleUser;
  //   await GoogleSignIn().signIn();

  //   GoogleSignInAuthentication? googleAuth;
  //   await googleUser?.authentication;

  //   AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);
  //   UserCredential userCredential =
  //       await FirebaseAuth.instance.signInWithCredential(credential);

  //   //debugPrint(UserCredential.user?.displayName);
  // }

  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // GoogleSignIn().signIn() isn't supported on web; Firebase Auth's
        // popup flow handles the OAuth exchange directly.
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(GoogleAuthProvider());
      } else {
        GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          // User canceled the Google Sign In flow
          return;
        }

        GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Handle sign-in success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In Successful')),
      );

      // Navigate to HomePage after successful sign-in
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Handle sign-in failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: $e'),
        ),
      );
    }
  }
}
