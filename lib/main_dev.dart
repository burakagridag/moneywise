// Development flavor entry point.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// ignore: constant_identifier_names
const String kFlavor = 'dev';

void main() {
  runApp(const ProviderScope(child: MoneyWiseApp()));
}
