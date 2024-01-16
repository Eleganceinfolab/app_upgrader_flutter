import 'package:flutter/material.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';

/// A widget to display the upgrade card.
class AppUpgradeCard extends UpgradeBase {
  /// The empty space that surrounds the card.
  ///
  /// The default margin is 4.0 logical pixels on all sides:
  /// `EdgeInsets.all(4.0)`.
  final EdgeInsetsGeometry margin;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// Creates a new [AppUpgradeCard].
  AppUpgradeCard({
    super.key,
    Upgrader? AppUpgrader,
    this.margin = const EdgeInsets.all(4.0),
    this.maxLines = 15,
    this.overflow = TextOverflow.ellipsis,
  }) : super(AppUpgrader ?? Upgrader.sharedInstance);

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (appUpgrader.debugLogging) {
      print('AppUpgrader: build AppUpgradeCard');
    }

    return StreamBuilder(
        initialData: state.widget.appUpgrader.evaluationReady,
        stream: state.widget.appUpgrader.evaluationStream,
        builder: (BuildContext context,
            AsyncSnapshot<UpgraderEvaluateNeed> snapshot) {
          if ((snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active) &&
              snapshot.data != null &&
              snapshot.data!) {
            if (appUpgrader.shouldDisplayUpgrade()) {
              return buildUpgradeCard(context, state);
            } else {
              if (appUpgrader.debugLogging) {
                print('AppUpgrader: AppUpgradeCard will not display');
              }
            }
          }
          return const SizedBox.shrink();
        });
  }

  /// Build the AppUpgradeCard Widget.
  Widget buildUpgradeCard(BuildContext context, UpgradeBaseState state) {
    final appMessages = appUpgrader.determineMessages(context);
    final title = appMessages.message(UpgraderMessage.title);
    final message = appUpgrader.body(appMessages);
    final releaseNotes = appUpgrader.releaseNotes;
    final shouldDisplayReleaseNotes = appUpgrader.shouldDisplayReleaseNotes();
    if (appUpgrader.debugLogging) {
      print('AppUpgrader: AppUpgradeCard: will display');
      print('AppUpgrader: AppUpgradeCard: showDialog title: $title');
      print('AppUpgrader: AppUpgradeCard: showDialog message: $message');
      print(
          'AppUpgrader: AppUpgradeCard: shouldDisplayReleaseNotes: $shouldDisplayReleaseNotes');

      print(
          'AppUpgrader: AppUpgradeCard: showDialog releaseNotes: $releaseNotes');
    }

    Widget? notes;
    if (shouldDisplayReleaseNotes && releaseNotes != null) {
      notes = Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(appMessages.message(UpgraderMessage.releaseNotes) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                releaseNotes,
                maxLines: maxLines,
                overflow: overflow,
              ),
            ],
          ));
    }

    return Card(
        color: Colors.white,
        margin: margin,
        child: AlertStyleWidget(
            title: Text(title ?? ''),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message),
                Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                        appMessages.message(UpgraderMessage.prompt) ?? '')),
                if (notes != null) notes,
              ],
            ),
            actions: <Widget>[
              if (appUpgrader.showIgnore)
                TextButton(
                    child: Text(appMessages
                            .message(UpgraderMessage.buttonTitleIgnore) ??
                        ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      appUpgrader.saveLastAlerted();

                      appUpgrader.onUserIgnored(context, false);
                      state.forceUpdateState();
                    }),
              if (appUpgrader.showLater)
                TextButton(
                    child: Text(
                        appMessages.message(UpgraderMessage.buttonTitleLater) ??
                            ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      appUpgrader.saveLastAlerted();

                      appUpgrader.onUserLater(context, false);
                      state.forceUpdateState();
                    }),
              TextButton(
                  child: Text(
                      appMessages.message(UpgraderMessage.buttonTitleUpdate) ??
                          ''),
                  onPressed: () {
                    // Save the date/time as the last time alerted.
                    appUpgrader.saveLastAlerted();

                    appUpgrader.onUserUpdated(context, false);
                    state.forceUpdateState();
                  }),
            ]));
  }
}
