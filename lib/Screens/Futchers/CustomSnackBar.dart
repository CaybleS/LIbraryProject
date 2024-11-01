import 'package:flutter/material.dart';

class CustomSnackBar {
  static SnackBar build({
    required String message,
    bool isError = false,
    IconData? icon,
    Color backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 3),
    double elevation = 10.0,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    EdgeInsetsGeometry margin = const EdgeInsets.all(10),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20),
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    String actionLabel = '',
    Color actionTextColor = Colors.white,
    VoidCallback? onActionPressed,
    VoidCallback? onVisible,
  }) {
    return SnackBar(
      content: Row(
        children: [
          if(icon != null)
            Icon(icon , color: Colors.white,),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message),
          ),

        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: duration,
      elevation: elevation,
      behavior: behavior,
      margin: margin,
      padding: padding,
      shape: shape,
      action: actionLabel.isNotEmpty
          ? SnackBarAction(
        label: actionLabel,
        textColor: actionTextColor,
        onPressed: onActionPressed ?? () {},
      )
          : null,
      onVisible: onVisible,
    );
  }
}
