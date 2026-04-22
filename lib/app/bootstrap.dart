import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hungry/core/config/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}
