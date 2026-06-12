import 'package:flutter/material.dart';

/// Shared route observer so screens can react when they become visible
/// again after a pushed route (e.g. the camera/pin creation flow) pops.
final RouteObserver<PageRoute> kRouteObserver = RouteObserver<PageRoute>();

/// App-wide navigator key, used to show UI (snackbars, dialogs, navigation)
/// from places without a BuildContext, such as the FCM foreground message
/// handler on web.
final GlobalKey<NavigatorState> kNavigatorKey = GlobalKey<NavigatorState>();
