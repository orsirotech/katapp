import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/catalog.dart';
import 'data/learn.dart';
import 'ui/screens.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = await Catalog.load(rootBundle);
  final learn = await Learn.load(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  final app = AppState(catalog, learn, prefs);
  runApp(KatApp(app: app));
  app.syncReminder();
}

class KatApp extends StatelessWidget {
  final AppState app;
  const KatApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KatApp',
        debugShowCheckedModeBanner: false,
        theme: K.theme(),
        home: Shell(app: app),
      );
}
