import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appcastURL =
        'https://github.com/Eleganceinfolab/app_upgrader_flutter/blob/main/lib/testappcast_macos.xml';
    final cfg = AppcastConfiguration(url: appcastURL, supportedOS: ['macos']);

    return MaterialApp(
      title: 'App Upgrader Flutter Example',
      home: AppUpgradeAlert(
          AppUpgrader: Upgrader(
            appcastConfig: cfg,
            debugLogging: true,
          ),
          child: Scaffold(
            appBar: AppBar(title: Text('App Upgrader Flutter Example')),
            body: Center(child: Text('Checking...')),
          )),
    );
  }
}
