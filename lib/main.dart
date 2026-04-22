import 'package:flutter/material.dart';
import 'package:hungry/app/app.dart';
import 'package:hungry/app/bootstrap.dart';

Future<void> main() async {
  await bootstrapApp();
  runApp(const HungryApp());
}
