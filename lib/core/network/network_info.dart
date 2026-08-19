import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    try {
      final dynamic result = await connectivity.checkConnectivity();
      if (result is List) {
        if (result.isEmpty) return false;
        return !result.contains(ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }
}
