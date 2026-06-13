import 'package:connectivity_plus/connectivity_plus.dart';

/// Returns true if the device currently reports an active network
/// interface (Wi-Fi, mobile data, ethernet, etc). This doesn't guarantee
/// the connection has working internet access, only that one is up.
Future<bool> hasNetworkConnection() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}
