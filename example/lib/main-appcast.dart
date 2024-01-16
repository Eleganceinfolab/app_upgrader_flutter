import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, setup the Appcast.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appcastURL =
        'https://github.com/Eleganceinfolab/app_upgrader_flutter/blob/main/lib/testappcast.xml';
    final cfg = AppcastConfiguration(url: appcastURL, supportedOS: ['android']);

    return MaterialApp(
      title: 'App Upgrader Flutter Example',
      home: Scaffold(
          appBar: AppBar(
              title: Text('App Upgrader FlutterappUpgrader Appcast Example')),
          body: AppUpgradeAlert(
            appUpgrader: Upgrader(
              appcastConfig: cfg,
              debugLogging: true,
            ),
            child: Center(child: Text('Checking...')),
          )),
    );
  }
}
