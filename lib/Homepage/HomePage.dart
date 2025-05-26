import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
// import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kindmap/main.dart';
import 'package:kindmap/map.dart';

import 'package:kindmap/themes/kmTheme.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../Services/map_services.dart';

class AnimationInfo {
  final AnimationTrigger trigger;
  final bool applyInitialState;
  final List<Effect> effects;

  AnimationInfo({
    required this.trigger,
    required this.applyInitialState,
    required this.effects,
  });
}

enum AnimationTrigger {
  onPageLoad,
  onActionTrigger,
}

abstract class Effect {
  final Curve curve;
  final Duration delay;
  final Duration duration;

  Effect({
    required this.curve,
    required this.delay,
    required this.duration,
  });
}

class MoveEffect extends Effect {
  final Offset begin;
  final Offset end;

  MoveEffect({
    required Curve curve,
    required Duration delay,
    required Duration duration,
    required this.begin,
    required this.end,
  }) : super(curve: curve, delay: delay, duration: duration);
}

void setupAnimations(Iterable<AnimationInfo> animations, TickerProvider vsync) {
  // Implementation for animations if needed
}

extension WidgetAnimationExtension on Widget {
  Widget animateOnActionTrigger(AnimationInfo animation) {
    // Return the widget as-is since we're removing animation functionality
    return this;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final unfocusNode = FocusNode();
  LatLng? location;
  List<Marker> markers = [];
  final Map<String, AnimationInfo> animationsMap = {}; // Define animationsMap
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> getLocation() async {
    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      location = LatLng(position.latitude, position.longitude);
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        location = LatLng(position.latitude, position.longitude);
      });

      // Subscribe to grid after getting location
      if (location != null) {
        await _subscribeToGrid(location!);
      }
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  Future<String> getAccessToken() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "kindmap-999d3",
      "private_key_id": "17c31e6a632800b89dcc51ea5741db18908734d5",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCTRc9ik4ni99tP\nFc9JjUcZPdQ3/WeXbSZdh09Lbpjmq89G86qQpwv+KwojXK8w5wgSuee07ps2Jyum\nTGDE8SQqx5rvT0RdhBRZ+lJiKFHsORB4xhzFwnhYNDYHI1ZQYNArvprBQ70kzucd\nibpV2/5/R7codjFLji4+JKMuPL3NF8JjZ7rEBrAxgWQlgwId4ab0P1y3Db0gmJLE\nTXwMqh2AlPHi8CK0n+jrEQ/0hOAwSd/PXAczFGHqDX+zdMQ9OJ+/7457YHM2mx7h\nJJDDb1Nvv9NbgGQA4gJ3WdbPeJPJvFroc2IWYjTKlyq0KY4oOCRjW34MYTUA4ggc\ng0CqzvqvAgMBAAECggEAArlUVCTuycwUJNrTlNna76G/9px7xDETIsC5cTzlnBf1\nGKwHbW8sNB0fWLcX+xtoKqcrR3fwVqiT0JrHYW0lDPDYh0ZGjpo+TB8VU1Zz6XQc\nFLfJWXO23nQcxGCyxyrQlDaNeIykXMrCOz7MZlZ61xIrAOxquKneZheEYyW2zFUg\necAe+ESb7an/i0oDsyRAUTega+eLoqYehhNtXzZFnY4BFAJZu4X2zhi9jnKpPFSr\n889oIbHmAbZ/A+mYHZGYqOAvNH7PoB9t16W2Ewex8nk1Wbpki+emwwul49NfgjaJ\nmAYGyXu9a5uhZ2OOSTIrn1iJKR8JhlGA/OKo5Zn2IQKBgQDMwsXZL2u4EgGNfDAL\nMG0Ubrqe3X792GEJEe7O9GCky6YSWClYk7roe8ZAvQtzPU3v+jd4z4S69EpBILo0\nCl2852bMJn+GgEvSjIYvmvNRJWc4bS9KQhV8qbigFrNmaHa7VFEYka5/JZ2QUGDJ\n2wDw5pjGfN2rFEk1YnqU2W59oQKBgQC4IEcOqILaE3oXpdy8CttKcPluXVkzm56H\nKAyjmNZfgYSLjiKtbtpxceMm9mGXrpzXMoT6SV3xu9M2LhKW2hwPn9yw3sicrzAn\nmijx8yL/DT5ZVYDOo4xtBFj26YAC+4m9Bu02XkJj3/UPWdTfmQr1o8w4JLbl5Mbe\nZp31pQ52TwKBgDuwCzxkNmJR3WIA8YBRfXqXTI9CweH9UUvzjkmFsyZWtvJiAKtx\nZOqgKgp1EQFmvXFW3xS4aViWHY8emyjQXMLUMYMRNdtfSrr1e6gk4wikfpJUQZTD\n7r+IOelwtJsFmJbC3WDsFpG5xVRsGcq9rGiMz7wMahGUuEJ3koQRXcQBAoGAVmxI\nDfhIWuWzc/AVGGocHefDG+tS2CdeFGBW9l7hmDhppztSyYbznzXugbY5foGl+lgr\nFHNlVfZsH80mSoobi7XkV1xqWyjbeGsidtZBgeeMcU/xwov/eJgGzfYxcLTyJLhg\nlRlPHiPbmZX3le/2te9pBp0s/+EO+wq9b7RGgn8CgYBYL4ifTzjLYmpkX2tpI68L\nSK6JA8XbglHdllKq1QuGmX7XkpEGPj/v6lo/KHDMhTj6ysM4rn9/0IqXKlVHbC+W\n02NuRbrpOIRg9kKcuOKInGTae7GCmKbC3/d2BsMHkFs3831GxUp9VVckhuQDZXiG\n4/kYhaBJwRaqpEjWSwpPww==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-ga6hv@kindmap-999d3.iam.gserviceaccount.com",
      "client_id": "109937053761461466716",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-ga6hv%40kindmap-999d3.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    var client =
        await clientViaServiceAccount(serviceAccountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  Future<void> sendNotification(String topic) async {
    final fburl = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/kindmap-999d3/messages:send');
    final accessToken = await getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final body = {
      'notification': {
        'title': 'KindMap',
        'body': 'Someone nearby needs help.',
      },
      'priority': 'high',
      'topic': '/topics/$topic',
    };
    final response = await http.post(
      fburl,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      print('Notification sent successfully to topic: $topic');
      MoveEffect(
        curve: Curves.easeInOut,
        delay: const Duration(milliseconds: 0),
        duration: const Duration(milliseconds: 600),
        begin: const Offset(0, 0),
        end: const Offset(0, 0),
      );

      final animationsMap = {
        'endDrawerOnActionTriggerAnimation': AnimationInfo(
          trigger: AnimationTrigger.onActionTrigger,
          applyInitialState: true,
          effects: [
            MoveEffect(
              curve: Curves.easeInOut,
              delay: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 600),
              begin: const Offset(0, 0),
              end: const Offset(0, 0),
            ),
          ],
        ),
      };
      //Added a Curely bracket to close the if statement
    }
  }

  Future<void> _subscribeToGrid(LatLng location) async {
    try {
      final gridId = _getGridId(location);
      await FirebaseMessaging.instance.subscribeToTopic(gridId);
      print('Subscribed to grid: $gridId');
    } catch (e) {
      print('Error subscribing to grid: $e');
    }
  }

  String _getGridId(LatLng loc) {
    // Round lat/lng to 2km grid
    final latGrid = (loc.latitude * 100).floor() ~/ 2;
    final lngGrid = (loc.longitude * 100).floor() ~/ 2;
    return 'grid_${latGrid}_${lngGrid}';
  }

  Future<void> sendGridNotification(LatLng location) async {
    try {
      final gridId = _getGridId(location);
      final fburl = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/kindmap-999d3/messages:send');
      final accessToken = await getAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final body = {
        'message': {
          'notification': {
            'title': 'KindMap',
            'body': 'Someone nearby needs help! [Grid: $gridId]',
          },
          'topic': gridId,
        },
      };

      final response = await http.post(
        fburl,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Grid notification sent successfully to: $gridId');
      } else {
        print('Failed to send grid notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending grid notification: $e');
    }
  }

  void navigateToPin(LatLng target) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch navigation';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: $e')),
      );
    }
  }

  void onPinTap(LatLng pinLocation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation'),
        content: const Text('Would you like to navigate to this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              navigateToPin(pinLocation);
            },
            child: const Text('Navigate'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final mapProvider = Provider.of<MapProvider>(context);
    return GestureDetector(
      onTap: () => unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: KMTheme.of(context).alternate,
          endDrawer: Drawer(
            elevation: 16,
            child: SizedBox(
              child: Container(
                // width: 407,
                // height: 933,
                decoration: BoxDecoration(
                  color: KMTheme.of(context).tertiary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: Stack(
                  children: [
                    Opacity(
                      opacity: Theme.of(context).brightness == Brightness.light
                          ? 0.2
                          : 0.7,
                      child: Container(
                        // width: 355,
                        // height: 957,
                        width: size.width * 1.3,
                        height: size.height * 1.3,
                        decoration: BoxDecoration(
                          color: KMTheme.of(context).tertiary,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: Image.asset(
                              'assets/images/img_menubar.png',
                            ).image,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(0),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      // alignment: const AlignmentDirectional(0.11, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: KMTheme.of(context).primaryBackground,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 0,
                                  color: Color(0x33000000),
                                  offset: Offset(
                                    4,
                                    4,
                                  ),
                                )
                              ],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(0),
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(0),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Container(
                                        width: size.width * 0.3,
                                        height: size.width * 0.3,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(FirebaseAuth
                                                  .instance.currentUser?.uid)
                                              .snapshots(),
                                          builder: ((context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data?.data() != null) {
                                              final data =
                                                  snapshot.data!.data()!;
                                              int? avatarIndex =
                                                  data['avatarIndex'];
                                              return FittedBox(
                                                child: Image.asset(
                                                    'assets/images/avatar${avatarIndex ?? 0}.png'),
                                              );
                                            }
                                            return const Center(
                                                child:
                                                    LinearProgressIndicator());
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            10, 0, 10, 10),
                                    child: StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth
                                                .instance.currentUser?.uid)
                                            .snapshots(),
                                        builder: ((context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data?.data() != null) {
                                            final data = snapshot.data!.data()!;
                                            final name =
                                                data['name'] ?? 'No Name';
                                            return FittedBox(
                                                child: Text(
                                              name,
                                              style: KMTheme.of(context)
                                                  .bodyMedium
                                                  .copyWith(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 22.5,
                                                    letterSpacing: 0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ));
                                          }
                                          return const Center(
                                              child: LinearProgressIndicator());
                                        })),
                                    // Text(
                                    //   'User name here',
                                    //   style: KMTheme.of(context)
                                    //       .bodyMedium
                                    //       .override(
                                    //         fontFamily: 'Plus Jakarta Sans',
                                    //         fontSize: 22.5,
                                    //         letterSpacing: 0,
                                    //         fontWeight: FontWeight.bold,
                                    //       ),
                                    // ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Opacity(
                          //   opacity: 0,
                          //   child: Container(
                          //     height: 70 % size.height,
                          //     decoration: BoxDecoration(
                          //       color: KMTheme.of(context).secondaryBackground,
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     alignment: const AlignmentDirectional(-1, 0),
                          //   ),
                          // ),
                          SizedBox(
                            height: size.height * 0.2,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 10),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.of(context).pushNamed('/settings');
                              },
                              child: ListTile(
                                leading: Icon(
                                  Icons.settings_sharp,
                                  color: KMTheme.of(context).primaryText,
                                ),
                                title: Text(
                                  'Settings',
                                  textAlign: TextAlign.start,
                                  style:
                                      KMTheme.of(context).titleLarge.copyWith(
                                            fontFamily: 'Plus Jakarta Sans',
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                                tileColor:
                                    KMTheme.of(context).secondaryBackground,
                                dense: false,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 10),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).pushNamed('/contact');
                              },
                              leading: Icon(
                                Icons.info,
                                color: KMTheme.of(context).primaryText,
                              ),
                              title: Text(
                                'Contact',
                                textAlign: TextAlign.start,
                                style: KMTheme.of(context).titleLarge.copyWith(
                                      fontFamily: 'Plus Jakarta Sans',
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              tileColor:
                                  KMTheme.of(context).secondaryBackground,
                              dense: false,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 10),
                            child: Slidable(
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                //extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    label: 'Share',
                                    backgroundColor: KMTheme.of(context).info,
                                    icon: Icons.share,
                                    onPressed: (_) {
                                      print('SlidableActionWidget pressed ...');
                                    },
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.share,
                                  color: KMTheme.of(context).primaryText,
                                ),
                                title: Text(
                                  'Share',
                                  textAlign: TextAlign.start,
                                  style:
                                      KMTheme.of(context).titleLarge.copyWith(
                                            fontFamily: 'Plus Jakarta Sans',
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                                tileColor:
                                    KMTheme.of(context).secondaryBackground,
                                dense: false,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 10),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).pushNamed('/about');
                              },
                              leading: Icon(
                                Icons.info,
                                color: KMTheme.of(context).primaryText,
                              ),
                              title: Text(
                                'About',
                                textAlign: TextAlign.start,
                                style: KMTheme.of(context).titleLarge.copyWith(
                                      fontFamily: 'Plus Jakarta Sans',
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              tileColor:
                                  KMTheme.of(context).secondaryBackground,
                              dense: false,
                            ),
                          ),
                          Opacity(
                            opacity: 0,
                            child: Container(
                              height: 50 % size.height,
                              decoration: BoxDecoration(
                                color: KMTheme.of(context).secondaryBackground,
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1, 0),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                width: 0.2 * size.width,
                                height: 0.1 * size.width,
                                decoration: BoxDecoration(
                                  color: KMTheme.of(context).lineColor,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 8,
                                      color: Colors.black,
                                      offset: Offset(2, 3),
                                      spreadRadius: 1,
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: KMTheme.of(context).accent1,
                                    width: 4,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Stack(
                                    alignment: const AlignmentDirectional(0, 0),
                                    children: [
                                      if (Theme.of(context).brightness ==
                                          Brightness.light)
                                        Align(
                                          alignment: const AlignmentDirectional(
                                              -0.74, -0.2),
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 0, 6, 0),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                Provider.of<ThemeProvider>(
                                                        context,
                                                        listen: false)
                                                    .toggleTheme();
                                              },
                                              child: Icon(
                                                Icons.nights_stay,
                                                color: KMTheme.of(context)
                                                    .primaryText,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (Theme.of(context).brightness ==
                                          Brightness.dark)
                                        Align(
                                          alignment: const AlignmentDirectional(
                                              0.70, 0.25),
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(5, 0, 0, 0),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                Provider.of<ThemeProvider>(
                                                        context,
                                                        listen: false)
                                                    .toggleTheme();
                                              },
                                              child: Icon(
                                                Icons.wb_sunny_rounded,
                                                color: KMTheme.of(context)
                                                    .primaryText,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animateOnActionTrigger(
            animationsMap['endDrawerOnActionTriggerAnimation'] ??
                AnimationInfo(
                  trigger: AnimationTrigger.onActionTrigger,
                  applyInitialState: true,
                  effects: [],
                ),
          ),
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: KMTheme.of(context).secondaryBackground,
            iconTheme: IconThemeData(color: KMTheme.of(context).primaryText),
            automaticallyImplyLeading: true,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/KindMap-logo-f.png',
                  // width: 500,
                  // height: 500,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Align(
              alignment: const AlignmentDirectional(-1, 0),
              child: Text(
                'KindMap',
                textAlign: TextAlign.start,
                style: KMTheme.of(context).titleMedium.copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                      color: KMTheme.of(context).primaryText,
                      fontSize: 24,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            actions: const [],
            centerTitle: false,
            elevation: 5,
          ),
          body: SafeArea(
            top: true,
            child: Stack(
              children: [
                Maps(),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: KMTheme.of(context).primaryBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                  ),
                ),
                PinSomeone(size, context)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget PinSomeone(Size size, BuildContext context) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: size.height * 0.08,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 32, 32, 32),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Color(0x33000000),
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            Navigator.of(context).pushNamed('/camera');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Pin Someone',
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        fontFamily: 'Plus Jakarta Sans',
                        color: KMTheme.of(context).primaryBtnText,
                        fontSize: 20,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.share_location,
                  color: KMTheme.of(context).primaryBtnText,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
