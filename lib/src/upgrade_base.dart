import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

class UpgradeBase extends StatefulWidget {
  /// The upgraders used to configure the upgrade dialog.
  final Upgrader AppUpgrader;

  const UpgradeBase(this.AppUpgrader, {Key? key}) : super(key: key);

  Widget build(BuildContext context, UpgradeBaseState state) {
    return Container();
  }

  @override
  UpgradeBaseState createState() => UpgradeBaseState();
}

class UpgradeBaseState extends State<UpgradeBase> {
  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) => widget.build(context, this);

  Future<bool> initialize() => widget.AppUpgrader.initialize();

  void forceUpdateState() => setState(() {});

  @override
  void dispose() {
    if (widget.AppUpgrader.debugLogging) {
      print('AppUpgrader: dispose');
    }
    super.dispose();
  }
}
