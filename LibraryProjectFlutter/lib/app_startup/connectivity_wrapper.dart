import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({required this.child, super.key});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late final StreamSubscription _subscription;
  late final AppLifecycleListener _listener;
  bool _snackbarVisible = false;

  @override
  void initState() {
    super.initState();
    _subscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        //_dismissNoInternetSnackbar();
      }
      else if (status == InternetStatus.disconnected) {
        //_showNoInternetSnackbar();
      }
    });
    _listener = AppLifecycleListener(
      onResume: _subscription.resume,
      onHide: _subscription.pause,
      onPause: _subscription.pause,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _listener.dispose();
    super.dispose();
  }

  void _showNoInternetSnackbar() {
    if (!_snackbarVisible) {
      _snackbarVisible = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have no internet"),
          duration: Duration(days: 365),
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