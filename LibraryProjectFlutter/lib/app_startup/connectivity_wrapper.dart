import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
// Note that this connectivity_plus package doesnt seem to work with disconnecting internet on a laptop/computer running an
// emulator, at least with android studio. You just gotta test physically.

// used in another file to run initConnectivity() everytime the app is resumed (from being backgrounded)
final GlobalKey<ConnectivityWrapperState> connectivityKey = GlobalKey();

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({required this.child, super.key});

  @override
  State<ConnectivityWrapper> createState() => ConnectivityWrapperState();
}

class ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _snackbarVisible = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      // in this case we just assume they have wifi if we cant check connectivity; this will just cause the snackbar to either
      // dismiss or not appear, both safe outcomes in the case of any error.
      result = [ConnectivityResult.wifi];
      return;
    }

    if (!mounted) {
      return Future.value(null); // idk why this is here but its on the example so
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (result.contains(ConnectivityResult.none)) {
      _showNoInternetSnackbar();
    }
    else {
      _dismissNoInternetSnackbar();
    }
  }

  void _showNoInternetSnackbar() {
    if (!_snackbarVisible) {
      _snackbarVisible = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have no internet, reconnect to save changes."),
          duration: Duration(days: 365), // arbitrary "infinite" time
        ),
      );
    }
  }

  void _dismissNoInternetSnackbar() {
    if (_snackbarVisible) {
      _snackbarVisible = false;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}