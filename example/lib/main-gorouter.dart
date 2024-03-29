import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(MyApp());
}

GoRouter routerConfig = GoRouter(
  initialLocation: '/page2',
  routes: [
    GoRoute(
        path: '/page1',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen('page1')),
    GoRoute(
        path: '/page2',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen('page2')),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App Upgrader Flutter GoRouter Example',
      routerConfig: routerConfig,
      builder: (context, child) {
        return AppUpgradeAlert(
          navigatorKey: routerConfig.routerDelegate.navigatorKey,
          child: child ?? Text('child'),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Upgrader Flutter GoRouter Example')),
      body: Center(child: Text('Checking... $title')),
    );
  }
}
