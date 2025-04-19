import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/avtarser.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:provider/provider.dart';

class ProfileProvider extends ChangeNotifier {
  // Add any necessary state management logic here
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onDoubleTap: () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Change Avatar?'),
                      content: const Text('Do you want to change your avatar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  Navigator.of(context).pushNamed('/avatars');
                }
              },
              child: Container(
                width: size.width * 0.4,
                height: size.width * 0.4,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      int? avatarIndex = snapshot.data?['avatarIndex'];
                      return FittedBox(
                          child: Image.asset(
                              'assets/images/avatar${avatarIndex}.png'));
                    }
                    return const Center(child: LinearProgressIndicator());
                  }),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 4),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      return FittedBox(
                        child: Text(
                          snapshot.data!['name'],
                          style: KMTheme.of(context).bodyMedium.copyWith(
                                fontFamily: 'Readex Pro',
                                fontSize: 20,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      );
                    }
                    return const Center(child: LinearProgressIndicator());
                  }),
                ),
              ),
              Align(
                alignment: const AlignmentDirectional(-1, 0),
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: ((context, snapshot) {
                      if (snapshot.hasData) {
                        return Center(
                          child: Text(
                            snapshot.data!['email'],
                            style: KMTheme.of(context).bodyMedium.copyWith(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0,
                                ),
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    })),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NameUpdateSection extends StatelessWidget {
  const NameUpdateSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Align(
      alignment: const AlignmentDirectional(-1, 0),
      child: Container(
        width: 428,
        height: 100,
        decoration: BoxDecoration(
          color: KMTheme.of(context).secondaryBackground,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Align(
              alignment: const AlignmentDirectional(-0.95, 0),
              child: Padding(
                padding: const EdgeInsets.all(3.5),
                child: Text(
                  'Change name : ',
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
              child: TextFormField(
                controller: textController,
                autofocus: false,
                obscureText: false,
                decoration: InputDecoration(
                  labelStyle: KMTheme.of(context).labelMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                      ),
                  hintText: 'New Name',
                  hintStyle: KMTheme.of(context).labelMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                      ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KMTheme.of(context).primaryText,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KMTheme.of(context).primary,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KMTheme.of(context).error,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: KMTheme.of(context).error,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: KMTheme.of(context).bodyMedium.copyWith(
                      fontFamily: 'Readex Pro',
                      letterSpacing: 0,
                    ),
                onFieldSubmitted: (newValue) {
                  textController.clear();
                  if (newValue == '') return;
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .update({'name': newValue});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordChangeForm extends StatelessWidget {
  const PasswordChangeForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textController1 = TextEditingController();
    final textController2 = TextEditingController();
    bool passwordVisibility = false;

    return Align(
      alignment: const AlignmentDirectional(-1, 0),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 403,
          height: 266,
          decoration: BoxDecoration(
            color: KMTheme.of(context).accent4,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: KMTheme.of(context).primaryText,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Align(
                alignment: const AlignmentDirectional(-1, 0),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 6, 0),
                  child: Text(
                    'Change Password :',
                    style: KMTheme.of(context).bodyMedium.copyWith(
                          fontFamily: 'Readex Pro',
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: textController1,
                  autofocus: false,
                  obscureText: false,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: KMTheme.of(context).labelMedium.copyWith(
                          fontFamily: 'Readex Pro',
                          letterSpacing: 0,
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: KMTheme.of(context).tertiary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: KMTheme.of(context).primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: textController2,
                  autofocus: false,
                  obscureText: !passwordVisibility,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: KMTheme.of(context).labelMedium.copyWith(
                          fontFamily: 'Readex Pro',
                          letterSpacing: 0,
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: KMTheme.of(context).tertiary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: KMTheme.of(context).primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: InkWell(
                      onTap: () {
                        passwordVisibility = !passwordVisibility;
                      },
                      child: Icon(
                        passwordVisibility
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                      ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('Button pressed ...');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KMTheme.of(context).primary,
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change Password',
                  style: KMTheme.of(context).titleSmall.copyWith(
                        fontFamily: 'Readex Pro',
                        color: KMTheme.of(context).secondary,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinDateFooter extends StatelessWidget {
  const JoinDateFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0, 1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: ((context, snapshot) {
              if (snapshot.hasData) {
                return AutoSizeText(
                  'Joined KindMap on ${snapshot.data!['joined']}',
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        fontFamily: 'Open Sans',
                        color: const Color(0xB457636C),
                        letterSpacing: 0,
                        fontWeight: FontWeight.bold,
                      ),
                  minFontSize: 10,
                );
              }
              return const Center(child: LinearProgressIndicator());
            })),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: const [
              ProfileHeader(),
              NameUpdateSection(),
              PasswordChangeForm(),
              JoinDateFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
