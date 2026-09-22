import 'package:flutter/material.dart';

T buildScreenWithArguments<T>(
  BuildContext context,
  T Function(Map<String, dynamic>) builder, {
  Map<String, dynamic>? defaultArgs,
}) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? defaultArgs ?? {};
  return builder(args);
}
