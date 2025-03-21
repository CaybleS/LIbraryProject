import 'package:flutter/material.dart';

/// Conditional rendering class
class ConditionalWidget {
  ConditionalWidget._();

  /// A function which returns a single `Widget`
  ///
  /// - [conditionBuilder] is a function which returns a boolean.
  /// - [widgetBuilder] is a function which returns a `Widget`,
  ///  when [conditionBuilder] returns `true`.
  /// - [fallbackBuilder] is a function which returns a `Widget`,
  ///  when [conditionBuilder] returns `false`. If [fallbackBuilder] is
  /// not provided, a `Container()` will be returned.
  static Widget single({
    required BuildContext context,
    required bool Function(BuildContext context) conditionBuilder,
    required Widget Function(BuildContext context) widgetBuilder,
    Widget Function(BuildContext context)? fallbackBuilder,
  }) {
    if (conditionBuilder(context) == true) {
      return widgetBuilder(context);
    } else {
      return fallbackBuilder?.call(context) ?? const SizedBox();
    }
  }

  /// A function which returns a `List<Widget>`
  ///
  /// - [conditionBuilder] is the function which returns a boolean.
  /// - [widgetBuilder] is a function which returns a `List<Widget>`,
  ///  when [conditionBuilder] returns `true`.
  /// - [fallbackBuilder] is a function which returns a `List<Widget>`,
  ///  when [conditionBuilder] returns `false`. If [fallbackBuilder] is
  /// not provided, an empty list will be returned.
  static List<Widget> list({
    required BuildContext context,
    required bool Function(BuildContext context) conditionBuilder,
    required List<Widget> Function(BuildContext context) widgetBuilder,
    List<Widget> Function(BuildContext context)? fallbackBuilder,
  }) {
    if (conditionBuilder(context) == true) {
      return widgetBuilder(context);
    } else {
      return fallbackBuilder?.call(context) ?? [];
    }
  }
}