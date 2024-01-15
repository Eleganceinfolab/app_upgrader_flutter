import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Upgrader Flutter Example - Multiple',
      home: AppUpgradeAlert(
          child: Scaffold(
        appBar: AppBar(title: Text('App Upgrader Flutter Example - Multiple')),
        body: Center(child: AppUpgradeAlert(child: Text('Checking...'))),
      )),
    );
  }
}
