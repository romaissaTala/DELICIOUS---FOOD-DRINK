import 'package:flutter/material.dart';
import 'package:Delicious_App/app.dart';
import 'package:Delicious_App/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const DeliciousApp());
}