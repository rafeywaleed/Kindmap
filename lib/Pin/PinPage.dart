// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/Pin/PinConfirmation.dart';
import 'package:kindmap/themes/kmTheme.dart';
import 'package:latlong2/latlong.dart';

class PinPage extends StatefulWidget {
  final String imagePath;

  const PinPage({super.key, required this.imagePath});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final unfocusNode = FocusNode();
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  final FocusNode textFieldFocusNode1 = FocusNode();
  final FocusNode textFieldFocusNode2 = FocusNode();
  String? dropDownValue;
  LatLng? location;
  bool _isLoading = false;
  String? url;
  String? docName;

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

  Future<void> uploadImage() async {
    try {
      setState(() => _isLoading = true);

      final path =
          'Images/${DateTime.now().millisecondsSinceEpoch}.${widget.imagePath.split('.').last}';
      final fbs = FirebaseStorage.instance.ref().child(path);

      UploadTask uploadTask = fbs.putFile(File(widget.imagePath));
      final snapshot = await uploadTask.whenComplete(() {});
      var temp = await snapshot.ref.getDownloadURL().whenComplete(() {});

      setState(() {
        url = temp;
        docName =
            '${location!.latitude}-${location!.longitude}-${TimeOfDay.now().hour}:${TimeOfDay.now().minute}';
      });

      await FirebaseFirestore.instance.collection('Pins').doc(docName).set({
        'Note': textController1.text.isEmpty ? '(none)' : textController1.text,
        'Details':
            textController2.text.isEmpty ? '(none)' : textController2.text,
        'Timer': dropDownValue ?? '3 hr',
        'Latitude': location!.latitude,
        'Longitude': location!.longitude,
        'url': url!,
        'UploadTime': DateTime.now()
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload Complete')));

      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PinConfirmation(docName: docName!)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    getLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: KMTheme.of(context).accent4,
        body: Stack(
          children: [
            Column(
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
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                14, 14, 14, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: KMTheme.of(context).primaryText,
                                    size: 20,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.keyboard_control_outlined,
                                    color: KMTheme.of(context).primaryText,
                                    size: 20,
                                  ),
                                  onPressed: () {},
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
                                  color:
                                      KMTheme.of(context).secondaryBackground,
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
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                15, 0, 15, 10),
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
                                      alignment:
                                          const AlignmentDirectional(-1, 0),
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(10, 0, 10, 10),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: KMTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                            .fromSTEB(
                                                            15, 0, 0, 0),
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
                                                            color: KMTheme.of(
                                                                    context)
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
                                                            .fromSTEB(
                                                            8, 0, 8, 8),
                                                    child: TextFormField(
                                                      controller:
                                                          textController1,
                                                      focusNode:
                                                          textFieldFocusNode1,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText:
                                                            'ex: Food, Money\n(optional)',
                                                        hintStyle:
                                                            KMTheme.of(context)
                                                                .labelMedium
                                                                .copyWith(
                                                                  fontFamily:
                                                                      'Readex Pro',
                                                                  letterSpacing:
                                                                      0,
                                                                ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: KMTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(22),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: KMTheme.of(
                                                                    context)
                                                                .primary,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(22),
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
                                                            .fromSTEB(
                                                            15, 0, 0, 0),
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
                                                            .fromSTEB(
                                                            8, 0, 8, 8),
                                                    child: TextFormField(
                                                      controller:
                                                          textController2,
                                                      focusNode:
                                                          textFieldFocusNode2,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: '(optional)',
                                                        hintStyle:
                                                            KMTheme.of(context)
                                                                .labelMedium
                                                                .copyWith(
                                                                  fontFamily:
                                                                      'Readex Pro',
                                                                  letterSpacing:
                                                                      0,
                                                                ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: KMTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(22),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: KMTheme.of(
                                                                    context)
                                                                .primary,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(22),
                                                        ),
                                                      ),
                                                      style: KMTheme.of(context)
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            letterSpacing: 0,
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
                                                            .fromSTEB(
                                                            15, 0, 0, 0),
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
                                                            .fromSTEB(
                                                            15, 0, 0, 0),
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
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      15.0),
                                                  child: DropdownButton<String>(
                                                    value: dropDownValue,
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        dropDownValue =
                                                            newValue!;
                                                      });
                                                    },
                                                    items: <String>[
                                                      'Default (3 hrs)',
                                                      '1 hr',
                                                      '5 hr',
                                                      '10 hr',
                                                      '24 hr'
                                                    ].map<
                                                            DropdownMenuItem<
                                                                String>>(
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
                Container(
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
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : uploadImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KMTheme.of(context).primary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pin_drop, size: 15),
                              const SizedBox(width: 8),
                              Text(
                                'PIN',
                                style: KMTheme.of(context).titleSmall.copyWith(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: KMTheme.of(context).secondary,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
