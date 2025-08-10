// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kindmap/screens/auth_pages.dart/auth_screen.dart';
import 'package:kindmap/screens/pin_confirmation.dart';

import 'package:latlong2/latlong.dart';

import '../config/app_theme.dart';

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

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget? icon;
  final double width;
  final double height;
  final EdgeInsetsDirectional padding;
  final EdgeInsetsDirectional iconPadding;
  final Color color;
  final TextStyle textStyle;
  final BorderSide borderSide;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    required this.width,
    required this.height,
    required this.padding,
    required this.iconPadding,
    required this.color,
    required this.textStyle,
    required this.borderSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderSide,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Padding(
                  padding: iconPadding,
                  child: icon,
                ),
              Text(text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

// Replace the FadeEffect and MoveEffect with this AnimatedContainer implementation
class AnimatedEntryContainer extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const AnimatedEntryContainer({
    Key? key,
    required this.child,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<AnimatedEntryContainer> createState() => _AnimatedEntryContainerState();
}

class _AnimatedEntryContainerState extends State<AnimatedEntryContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

Map<String, dynamic> getCellInfo(double lat, double long) {
  const double kmPerLatDegree = 111.32;
  const double cellSizeKm = 2.0;

  final deltaLatDeg = cellSizeKm / kmPerLatDegree;
  final row = (lat / deltaLatDeg).floor();

  final swLat = row * deltaLatDeg;
  final swLatRad = swLat * pi / 180;
  final deltaLongDeg = cellSizeKm / (kmPerLatDegree * cos(swLatRad));
  final col = (long / deltaLongDeg).floor();

  return {
    'row': row,
    'col': col,
    'cellId': '${row}_${col}',
    'topic': 'grid_${row}_${col}',
    'deltaLatDeg': deltaLatDeg,
    'deltaLongDeg': deltaLongDeg,
  };
}

class PinPage extends StatefulWidget {
  final String imagePath;

  const PinPage({super.key, required this.imagePath});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> with TickerProviderStateMixin {
  final unfocusNode = FocusNode();
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final FocusNode textFieldFocusNode1 = FocusNode();
  final FocusNode textFieldFocusNode2 = FocusNode();
  String? dropDownValue;
  late LatLng location;
  final db = FirebaseFirestore.instance;
  String? url;
  late String cellId;
  late String docName;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      Position temp = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        location = LatLng(temp.latitude, temp.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to get location: $e'),
      ));
    }
  }

  Future uploadImage() async {
    try {
      print("ImagePath: ${widget.imagePath}");
      final base64Image = await _compressAndConvertImage(widget.imagePath);
      debugPrint("Base64Image: $base64Image");
      final cellInfo = getCellInfo(location.latitude, location.longitude);
      final cellId = cellInfo['cellId'];
      final topic = cellInfo['topic'];

      final pinRef = FirebaseFirestore.instance
          .collection('pins')
          .doc(cellId)
          .collection('markers')
          .doc();

      final pinData = {
        'id': pinRef.id,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'note': textController1.text.isEmpty ? '(none)' : textController1.text,
        'details':
            textController2.text.isEmpty ? '(none)' : textController2.text,
        'timer': dropDownValue ?? '3 hr',
        'imageBase64': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'grid': cellId,
      };

      await pinRef.set(pinData);

      setState(() {
        this.cellId = cellId;
        docName = pinRef.id;
      });

      await sendNotification(topic);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pin created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating pin: $e')));
    }
  }

  Future<void> sendNotification(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    final fburl = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/kindmap-999d3/messages:send');
    final accessToken = await getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final body = {
      'message': {
        'topic': topic,
        'notification': {
          'title': 'New Help Request Nearby',
          'body': 'Someone needs assistance in your area',
        },
        'data': {
          'type': 'new_pin',
          'grid': topic.replaceFirst('grid_', ''),
          'timestamp': DateTime.now().toIso8601String(),
        },
      }
    };

    final response = await http.post(
      fburl,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      print('Notification sent successfully to topic: $topic');
    } else {
      print('Error sending notification: ${response.body}');
    }
  }

  Future<String> getAccessToken() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson({
      //* Add your service account credentials here
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    var client =
        await clientViaServiceAccount(serviceAccountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getLocation();
    getDotnev();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  Future<void> getDotnev() async {
    await dotenv.load(fileName: ".env");
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    textController1.dispose();
    textController2.dispose();
    textFieldFocusNode1.dispose();
    textFieldFocusNode2.dispose();
    super.dispose();
  }

  Future<String> _compressAndConvertImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 800,
        minWidth: 800,
        quality: 85,
      );

      return base64Encode(compressed);
    } catch (e) {
      print('Error compressing image: $e');
      final bytes = await File(imagePath).readAsBytes();
      return base64Encode(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: KMTheme.of(context).accent4,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(5, 12, 5, 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 30,
                              borderWidth: 1,
                              buttonSize: 40,
                              fillColor:
                                  KMTheme.of(context).secondaryBackground,
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                color: KMTheme.of(context).primaryText,
                                size: 20,
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                CustomIconButton(
                                  borderColor: Colors.transparent,
                                  borderRadius: 30,
                                  borderWidth: 1,
                                  buttonSize: 40,
                                  fillColor:
                                      KMTheme.of(context).secondaryBackground,
                                  icon: Icon(
                                    Icons.keyboard_control_outlined,
                                    color: KMTheme.of(context).primaryText,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    print('IconButton pressed ...');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: const AlignmentDirectional(0, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: KMTheme.of(context).secondaryBackground,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(File(widget.imagePath)),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(15, 0, 15, 10),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: KMTheme.of(context).secondaryBackground,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(-1, 0),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            10, 0, 10, 10),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: KMTheme.of(context)
                                            .secondaryBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(5, 0, 5, 10),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      -1, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(15, 0, 0, 0),
                                                child: Text(
                                                  'Add a note: ',
                                                  style: KMTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontSize: 22,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            KMTheme.of(context)
                                                                .primaryText,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(8, 0, 8, 8),
                                                child: TextFormField(
                                                  controller: textController1,
                                                  focusNode:
                                                      textFieldFocusNode1,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    labelStyle:
                                                        KMTheme.of(context)
                                                            .labelMedium
                                                            .copyWith(
                                                              fontFamily:
                                                                  'Readex Pro',
                                                              letterSpacing: 0,
                                                            ),
                                                    hintText:
                                                        'ex: Food, Money\n(optional)',
                                                    hintStyle:
                                                        KMTheme.of(context)
                                                            .labelMedium
                                                            .copyWith(
                                                              fontFamily:
                                                                  'Readex Pro',
                                                              letterSpacing: 0,
                                                            ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .secondaryText,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .primary,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    errorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .error,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    focusedErrorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .error,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                  ),
                                                  style: KMTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontFamily:
                                                            'Readex Pro',
                                                        letterSpacing: 0,
                                                      ),
                                                  maxLines: 3,
                                                  minLines: null,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      -1, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(15, 0, 0, 0),
                                                child: Text(
                                                  'Location details:',
                                                  style: KMTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontSize: 22,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(8, 0, 8, 8),
                                                child: TextFormField(
                                                  controller: textController2,
                                                  focusNode:
                                                      textFieldFocusNode2,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    labelStyle:
                                                        KMTheme.of(context)
                                                            .labelMedium
                                                            .copyWith(
                                                              fontFamily:
                                                                  'Readex Pro',
                                                              letterSpacing: 0,
                                                            ),
                                                    hintText: '(optional)',
                                                    hintStyle:
                                                        KMTheme.of(context)
                                                            .labelMedium
                                                            .copyWith(
                                                              fontFamily:
                                                                  'Readex Pro',
                                                              letterSpacing: 0,
                                                            ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .secondaryText,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .primary,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    errorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .error,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    focusedErrorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            KMTheme.of(context)
                                                                .error,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                  ),
                                                  style: KMTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontFamily:
                                                            'Readex Pro',
                                                        letterSpacing: 0,
                                                      ),
                                                  minLines: null,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      -1, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(15, 0, 0, 0),
                                                child: Text(
                                                  'Timer:',
                                                  style: KMTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontSize: 22,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      -1, 0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(15, 0, 0, 0),
                                                child: FittedBox(
                                                  child: Text(
                                                    'Set the time, when the location you pinned\nshould disappear from the map',
                                                    style: KMTheme.of(context)
                                                        .bodyMedium
                                                        .copyWith(
                                                          fontFamily:
                                                              'Plus Jakarta Sans',
                                                          color: KMTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                          fontSize: 15,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(15.0),
                                              child: DropdownButton<String>(
                                                value: dropDownValue,
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    dropDownValue = newValue!;
                                                  });
                                                },
                                                items: <String>[
                                                  'Default (3 hrs)',
                                                  '1 hr',
                                                  '5 hr',
                                                  '10 hr',
                                                  '24 hr'
                                                ].map<DropdownMenuItem<String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                hint: const Text(
                                                    'Default (3 hrs)'),
                                                icon: const Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  size: 24,
                                                ),
                                                isExpanded: true,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedEntryContainer(
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: KMTheme.of(context).primaryBackground,
                ),
                alignment: const AlignmentDirectional(0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                      child: CustomButton(
                        onPressed: () async {
                          await uploadImage();
                          // Get cell info for topic
                          final cellInfo = getCellInfo(
                              location.latitude, location.longitude);
                          final cellName = cellInfo['topic'];
                          print("CellInfo: $cellInfo");
                          print("CellName: $cellName");
                          await sendNotification(cellName);
                          print("docname: $docName");
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PinConfirmation(
                                  cellId: cellId, docName: docName)));
                        },
                        text: 'Pin',
                        icon: Icon(Icons.pin_drop,
                            color: KMTheme.of(context).primaryBtnText,
                            size: 18),
                        width: double.infinity,
                        height: 50,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        iconPadding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 5, 0),
                        color: KMTheme.of(context).secondary,
                        textStyle: KMTheme.of(context).titleSmall.copyWith(
                              fontFamily: 'Plus Jakarta Sans',
                              color: KMTheme.of(context).primaryBtnText,
                              fontWeight: FontWeight.bold,
                            ),
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
