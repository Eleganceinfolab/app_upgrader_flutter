import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, the default behavior will be to use the Google Play Store
  // version of the app.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration()).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    print('_MyAppState.build called');
    return MaterialApp(
      title: 'App Upgrader Flutter StatefulWidget Example',
      home: AppUpgradeAlert(
          child: Scaffold(
        appBar:
            AppBar(title: Text('App Upgrader Flutter StatefulWidget Example')),
        body: Center(child: Text('Checking...')),
      )),
    );
  }
}
