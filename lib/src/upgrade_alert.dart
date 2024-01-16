import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

/// A widget to display the upgrade dialog.
class AppUpgradeAlert extends UpgradeBase {
  /// The [child] contained by the widget.
  final Widget? child;

  /// Creates a new [AppUpgradeAlert].
  AppUpgradeAlert(
      {Key? key, Upgrader? appUpgrader, this.child, this.navigatorKey})
      : super(appUpgrader ?? Upgrader.sharedInstance, key: key);

  /// For use by the Router architecture as part of the RouterDelegate.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (appUpgrader.debugLogging) {
      print('AppUpgrader: build AppUpgradeAlert');
    }

    return StreamBuilder(
      initialData: state.widget.appUpgrader.evaluationReady,
      stream: state.widget.appUpgrader.evaluationStream,
      builder:
          (BuildContext context, AsyncSnapshot<UpgraderEvaluateNeed> snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data != null &&
            snapshot.data!) {
          if (appUpgrader.debugLogging) {
            print("AppUpgrader: need to evaluate version");
          }

          final checkContext =
              navigatorKey != null && navigatorKey!.currentContext != null
                  ? navigatorKey!.currentContext!
                  : context;
          appUpgrader.checkVersion(context: checkContext);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
