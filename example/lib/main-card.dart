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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Upgrader Flutter Card Example',
      home: Scaffold(
        appBar: AppBar(title: Text('App Upgrader Flutter Card Example')),
        body: Container(
          margin: EdgeInsets.only(left: 12.0, right: 12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _simpleCard,
                _simpleCard,
                AppUpgradeCard(),
                _simpleCard,
                _simpleCard,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _simpleCard => Card(
        child: SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Text('Card')),
        ),
      );
}
