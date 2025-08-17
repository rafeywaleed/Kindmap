import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:kindmap/services/permission_services.dart';
import 'package:kindmap/services/theme_services.dart' show ThemeProvider;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../widgets/map.dart';
import '../widgets/pin_someone.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request permissions when app starts
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request location permission
    // final hasLocationPermission =
    //     await PermissionService.handleLocationPermission();
    // if (!hasLocationPermission) {
    //   if (mounted) {
    //     _showPermissionDialog(
    //       'Location Access Required',
    //       'KindMap needs location access to show nearby help requests. Please enable location access in settings.',
    //       'location',
    //     );
    //   }
    // }

    // Request notification permission
    final hasNotificationPermission =
        await PermissionService.handleNotificationPermission();
    if (!hasNotificationPermission) {
      if (mounted) {
        _showPermissionDialog(
          'Notifications',
          'Enable notifications to stay updated with nearby help requests.',
          'notification',
        );
      }
    }
  }

  void _showPermissionDialog(String title, String message, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (type == 'location') {
                await Geolocator.openLocationSettings();
              } else {
                await openAppSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: KMTheme.of(context).alternate,
        endDrawer: Drawer(
          elevation: 16,
          child: SizedBox(
            child: Container(
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
                        GestureDetector(
                          onDoubleTap: () =>
                              Navigator.of(context).pushNamed('/profile'),
                          child: Container(
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
                                  ),
                                ),
                              ],
                            ),
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
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
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
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
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
                            tileColor: KMTheme.of(context).secondaryBackground,
                            dense: false,
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
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
                            tileColor: KMTheme.of(context).secondaryBackground,
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
                                            highlightColor: Colors.transparent,
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
                                            highlightColor: Colors.transparent,
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
    );
  }
}
