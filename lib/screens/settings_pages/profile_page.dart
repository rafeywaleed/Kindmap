import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

// Custom IconButton to replace FlutterFlowIconButton
class CustomIconButton extends StatelessWidget {
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double buttonSize;
  final Color fillColor;
  final Icon icon;
  final VoidCallback onPressed;

  const CustomIconButton({
    Key? key,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.buttonSize,
    required this.fillColor,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
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
  final unfocusNode = FocusNode();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Text controllers and focus nodes
  late TextEditingController textController1;
  late TextEditingController textController2;
  late TextEditingController textController3;
  late FocusNode textFieldFocusNode1;
  late FocusNode textFieldFocusNode2;
  late FocusNode textFieldFocusNode3;
  bool passwordVisibility = false;

  // Validators
  String? textController1Validator(BuildContext context, String? value) {
    return null;
  }

  String? textController2Validator(BuildContext context, String? value) {
    return null;
  }

  String? textController3Validator(BuildContext context, String? value) {
    return null;
  }

  @override
  void initState() {
    super.initState();
    textController1 = TextEditingController();
    textController2 = TextEditingController();
    textController3 = TextEditingController();
    textFieldFocusNode1 = FocusNode();
    textFieldFocusNode2 = FocusNode();
    textFieldFocusNode3 = FocusNode();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    textController1.dispose();
    textController2.dispose();
    textController3.dispose();
    textFieldFocusNode1.dispose();
    textFieldFocusNode2.dispose();
    textFieldFocusNode3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: KMTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: KMTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: CustomIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30,
            borderWidth: 1,
            buttonSize: 40,
            fillColor: Colors.transparent,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: KMTheme.of(context).primaryText,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Profile',
            style: KMTheme.of(context).bodyMedium.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  letterSpacing: 0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: false,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
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
                                    title: Text('Change Avatar?'),
                                    content: Text(
                                        'Do you want to change your avatar?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                // Navigate to the avatars page
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
                                    int? avatarIndex =
                                        snapshot.data?['avatarIndex'];
                                    return FittedBox(
                                        child: Image.asset(
                                            'assets/images/avatar${avatarIndex}.png'));
                                  }
                                  return const Center(
                                      child: LinearProgressIndicator());
                                }),
                              ),
                            ),
                          ),
                        )),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                8, 8, 8, 4),
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
                                      style: KMTheme.of(context)
                                          .bodyMedium
                                          .copyWith(
                                            fontFamily: 'Readex Pro',
                                            fontSize: 20,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  );
                                }
                                return const Center(
                                    child: LinearProgressIndicator());
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
                                        style: KMTheme.of(context)
                                            .bodyMedium
                                            .copyWith(
                                              fontFamily: 'Readex Pro',
                                              letterSpacing: 0,
                                            ),
                                      ),
                                    );
                                  }
                                  return const Center(
                                      child: CircularProgressIndicator());
                                })),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: const AlignmentDirectional(-1, 0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/trophy.png',
                            width: size.width * 0.2,
                            height: size.width * 0.2,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 10, 0, 0),
                            child: Text(
                              'Number of people you helped :',
                              style: KMTheme.of(context).bodyMedium.copyWith(
                                    fontFamily: 'Readex Pro',
                                    letterSpacing: 0,
                                  ),
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
                                    return Text(
                                      snapshot.data!['helped'].toString(),
                                      style: KMTheme.of(context)
                                          .bodyMedium
                                          .copyWith(
                                            fontFamily: 'Readex Pro',
                                            fontSize: 35,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    );
                                  }
                                  return const Center(
                                      child: LinearProgressIndicator());
                                })),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(0, 0),
                            child: Text(
                              'These many people are thankful \nfor you',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: KMTheme.of(context).bodyMedium.copyWith(
                                    fontFamily: 'Readex Pro',
                                    color: KMTheme.of(context).secondaryText,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
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
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                          child: TextFormField(
                            controller: textController1,
                            focusNode: textFieldFocusNode1,
                            autofocus: false,
                            obscureText: false,
                            decoration: InputDecoration(
                              labelStyle:
                                  KMTheme.of(context).labelMedium.copyWith(
                                        fontFamily: 'Readex Pro',
                                        letterSpacing: 0,
                                      ),
                              hintText: 'New Name',
                              hintStyle:
                                  KMTheme.of(context).labelMedium.copyWith(
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
                            minLines: null,
                            validator: (value) =>
                                textController1Validator(context, value),
                            onFieldSubmitted: (newValue) {
                              textController1.clear();
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
                ),
                Align(
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  8, 6, 6, 0),
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
                              controller: textController2,
                              focusNode: textFieldFocusNode2,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                labelStyle:
                                    KMTheme.of(context).labelMedium.copyWith(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0,
                                        ),
                                hintStyle:
                                    KMTheme.of(context).labelMedium.copyWith(
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
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: KMTheme.of(context).error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: KMTheme.of(context).error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              style: KMTheme.of(context).bodyMedium.copyWith(
                                    fontFamily: 'Readex Pro',
                                    letterSpacing: 0,
                                  ),
                              minLines: null,
                              validator: (value) =>
                                  textController2Validator(context, value),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: TextFormField(
                              controller: textController3,
                              focusNode: textFieldFocusNode3,
                              autofocus: false,
                              obscureText: !passwordVisibility,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle:
                                    KMTheme.of(context).labelMedium.copyWith(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0,
                                        ),
                                hintStyle:
                                    KMTheme.of(context).labelMedium.copyWith(
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
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: KMTheme.of(context).error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: KMTheme.of(context).error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: InkWell(
                                  onTap: () => setState(
                                    () => passwordVisibility =
                                        !passwordVisibility,
                                  ),
                                  focusNode: FocusNode(skipTraversal: true),
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
                              minLines: null,
                              validator: (value) =>
                                  textController3Validator(context, value),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              print('Button pressed ...');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KMTheme.of(context).primary,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  24, 0, 24, 0),
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
                ),
                Align(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
