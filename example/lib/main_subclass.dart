import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';
import 'package:flutter/material.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Upgrader Flutter Subclass Example',
      home: Scaffold(
          appBar: AppBar(title: Text('App Upgrader Flutter Subclass Example')),
          body: AppUpgradeAlert(
            appUpgrader: MyUpgrader(),
            child: Center(child: Text('Checking...')),
          )),
    );
  }
}

/// This class extends / subclasses Upgrader.
class MyUpgrader extends Upgrader {
  MyUpgrader() : super(debugLogging: true);

  /// This method overrides super class method.
  @override
  void popNavigator(BuildContext context) {
    print('this method overrides popNavigator');
    super.popNavigator(context);
  }
}
