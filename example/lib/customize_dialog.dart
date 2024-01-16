import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ValueNotifier<String> valueNotifierAppVersion = ValueNotifier('');
  ValueNotifier<String> valueNotifierInstalledVersion = ValueNotifier('');
  ValueNotifier<String> valueNotifierReleaseNote = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('App Upgrader Flutter Example')),
        body: AppUpgradeAlert(
          appUpgrader: Upgrader(
            customDialog: true,
            isDefaultButton: false,
            debugLogging: true,
            backgroundColor: Colors.white,
            customDialogShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            durationUntilAlertAgain: const Duration(seconds: 30),
            iconOrImage: Transform.rotate(
              angle: 0.600,
              child: Image.asset(
                'assets/images/ic_rocket.png',
                height: 150,
                width: 150,
              ),
            ),
            customContent: Container(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "What's new",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        ValueListenableBuilder(
                          valueListenable: valueNotifierAppVersion,
                          builder:
                              (BuildContext context, value, Widget? child) {
                            return Text(
                              value.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.orange),
                            );
                          },
                        ),
                      ],
                    ),
                    ValueListenableBuilder(
                        valueListenable: valueNotifierReleaseNote,
                        builder: (BuildContext context, value, Widget? child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              value.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        })
                  ]),
            ),
            updateButtonStyle: ButtonStyle(
              elevation: const MaterialStatePropertyAll(3),
              backgroundColor: const MaterialStatePropertyAll(Colors.orange),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.orange))),
            ),
            updateButtonTextStyle: const TextStyle(color: Colors.white),
            ignoreButtonStyle: ButtonStyle(
              backgroundColor: const MaterialStatePropertyAll(Colors.white),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.black))),
            ),
            ignoreButtonTextStyle: const TextStyle(color: Colors.black),
            laterButtonStyle: ButtonStyle(
              backgroundColor: const MaterialStatePropertyAll(Colors.white),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.red))),
            ),
            laterButtonTextStyle: const TextStyle(color: Colors.red),
            willDisplayUpgrade: (
                {appStoreVersion,
                required display,
                installedVersion,
                minAppVersion,
                releaseNote}) {
              valueNotifierAppVersion.value = appStoreVersion ?? '';
              valueNotifierInstalledVersion.value = installedVersion ?? '';
              valueNotifierReleaseNote.value = releaseNote ?? '';
            },
          ),
        ),
      ),
    );
  }
}
