import 'package:flutter/material.dart';

/// Shared route observer so screens can react when they become visible
/// again after a pushed route (e.g. the camera/pin creation flow) pops.
final RouteObserver<PageRoute> kRouteObserver = RouteObserver<PageRoute>();
