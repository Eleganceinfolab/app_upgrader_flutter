import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'appcast.dart';
import 'itunes_search_api.dart';
import 'play_store_search_api.dart';
import 'upgrade_os.dart';
import 'upgrade_messages.dart';

/// Signature of callbacks that have no arguments and return bool.
typedef BoolCallback = bool Function();

/// Signature of callbacks that have a bool argument and no return.
typedef VoidBoolCallback = void Function(bool value);

/// Signature of callback for willDisplayUpgrade. Includes display,
/// minAppVersion, installedVersion, and appStoreVersion.
typedef WillDisplayUpgradeCallback = void Function(
    {required bool display,
    String? minAppVersion,
    String? releaseNote,
    String? installedVersion,
    String? appStoreVersion});

/// The type of data in the stream.
typedef UpgraderEvaluateNeed = bool;

/// There are two different dialog styles: Cupertino and Material
enum UpgradeDialogStyle { cupertino, material }

/// A class to define the configuration for the appcast. The configuration
/// contains two parts: a URL to the appcast, and a list of supported OS
/// names, such as "android", "fuchsia", "ios", "linux" "macos", "web", "windows".
class AppcastConfiguration {
  final List<String>? supportedOS;
  final String? url;

  AppcastConfiguration({
    this.supportedOS,
    this.url,
  });
}

/// Creates a shared instance of [Upgrader].
Upgrader _sharedInstance = Upgrader();
const EdgeInsets _defaultInsetPadding =
    EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);

/// A class to configure the upgrade dialog.
class Upgrader with WidgetsBindingObserver {
  /// Provide an Appcast that can be replaced for mock testing.
  final Appcast? appcast;

  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  /// When an appcast is configured for iOS, the iTunes lookup is not used.
  final AppcastConfiguration? appcastConfig;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by [AppUpgradeCard]. (default: false)
  bool canDismissDialog;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  /// The country code that will override the system locale. Optional.
  final String? countryCode;

  /// The country code that will override the system locale. Optional. Used only for Android.
  final String? languageCode;

  /// For debugging, always force the upgrade to be available.
  bool debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  bool debugDisplayOnce;

  /// Enable print statements for debugging.
  bool debugLogging;

  /// The upgrade dialog style. Used only on AppUpgradeAlert. (default: material)
  UpgradeDialogStyle dialogStyle;

  /// Duration until alerting user again
  final Duration durationUntilAlertAgain;

  /// The localized messages used for display in AppUpgrader.
  UpgraderMessages? messages;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  String? minAppVersion;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onIgnore;

  /// Called when the later button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onLater;

  /// Called when the update button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onUpdate;

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Not used by [AppUpgradeCard].
  BoolCallback? shouldPopScope;

  /// Hide or show Ignore button on dialog (default: true)
  bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  bool showLater;

  /// Hide or show release notes (default: true)
  bool showReleaseNotes;

  /// The text style for the cupertino dialog buttons. Used only for
  /// [UpgradeDialogStyle.cupertino]. Optional.
  TextStyle? cupertinoButtonTextStyle;

  /// Called when [Upgrader] determines that an upgrade may or may not be
  /// displayed. The [value] parameter will be true when it should be displayed,
  /// and false when it should not be displayed. One good use for this callback
  /// is logging metrics for your app.
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  /// Provides information on which OS this code is running on.
  final UpgraderOS upgraderOS;

  bool _displayed = false;
  bool _initCalled = false;
  PackageInfo? _packageInfo;

  String? _installedVersion;
  String? _appStoreVersion;
  String? _appStoreListingURL;
  String? _releaseNotes;
  String? _updateAvailable;
  DateTime? _lastTimeAlerted;
  String? _lastVersionAlerted;
  String? _userIgnoredVersion;
  bool _hasAlerted = false;
  bool _isCriticalUpdate = false;

  /// Track the initialization future so that [initialize] can be called multiple times.
  Future<bool>? _futureInit;

  /// A stream that provides a new value each time an evaluation should be performed.
  /// The values will always be null or true.
  Stream<UpgraderEvaluateNeed> get evaluationStream => _streamController.stream;
  final _streamController = StreamController<UpgraderEvaluateNeed>.broadcast();

  /// An evaluation should be performed.
  bool get evaluationReady => _evaluationReady;
  bool _evaluationReady = false;

  bool customDialog;
  bool isDefaultButton;
  ShapeBorder? customDialogShape;
  Color? backgroundColor;
  Widget? customContent;
  Widget? customTitle;
  Widget? iconOrImage;
  ButtonStyle? updateButtonStyle;
  ButtonStyle? ignoreButtonStyle;
  ButtonStyle? laterButtonStyle;
  TextStyle? ignoreButtonTextStyle;
  TextStyle? laterButtonTextStyle;
  TextStyle? updateButtonTextStyle;
  EdgeInsetsGeometry? contentPadding;
  double? elevation;
  Color? shadowColor;
  EdgeInsetsGeometry? actionsPadding;

  MainAxisAlignment? actionsAlignment;

  OverflowBarAlignment? actionsOverflowAlignment;

  VerticalDirection? actionsOverflowDirection;

  double? actionsOverflowButtonSpacing;

  EdgeInsetsGeometry? buttonPadding;
  AlignmentGeometry? alignment;
  EdgeInsets insetPadding;
  Clip clipBehavior;
  bool scrollable;
  final notInitializedExceptionMessage =
      'initialize() not called. Must be called first.';

  Upgrader({
    this.appcastConfig,
    this.appcast,
    this.messages,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.willDisplayUpgrade,
    this.insetPadding = _defaultInsetPadding,
    this.clipBehavior = Clip.none,
    this.alignment,
    this.scrollable = false,
    this.isDefaultButton = false,
    this.backgroundColor,
    this.customTitle,
    this.contentPadding,
    this.customDialogShape,
    this.ignoreButtonStyle,
    this.laterButtonStyle,
    this.updateButtonStyle,
    this.updateButtonTextStyle,
    this.ignoreButtonTextStyle,
    this.laterButtonTextStyle,
    this.customContent,
    this.elevation,
    this.shadowColor,
    this.iconOrImage,
    this.actionsPadding,
    this.actionsAlignment,
    this.actionsOverflowAlignment,
    this.actionsOverflowDirection,
    this.actionsOverflowButtonSpacing,
    this.buttonPadding,
    this.customDialog = false,
    http.Client? client,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.canDismissDialog = false,
    this.countryCode,
    this.languageCode,
    this.minAppVersion,
    this.dialogStyle = UpgradeDialogStyle.material,
    this.cupertinoButtonTextStyle,
    UpgraderOS? upgraderOS,
  })  : client = client ?? http.Client(),
        upgraderOS = upgraderOS ?? UpgraderOS() {
    if (debugLogging) print("AppUpgrader: instantiated.");
  }

  /// A shared instance of [Upgrader].
  static Upgrader get sharedInstance => _sharedInstance;

  void installPackageInfo({PackageInfo? packageInfo}) {
    _packageInfo = packageInfo;
    _initCalled = false;
  }

  void installAppStoreVersion(String version) {
    _appStoreVersion = version;
  }

  void installAppStoreListingURL(String url) {
    _appStoreListingURL = url;
  }

  /// Initialize [Upgrader] by getting saved preferences, getting platform package info, and getting
  /// released version info.
  Future<bool> initialize() async {
    if (debugLogging) {
      print('AppUpgrader: initialize called');
    }
    if (_futureInit != null) return _futureInit!;

    _futureInit = Future(() async {
      if (debugLogging) {
        print('AppUpgrader: initializing');
      }
      if (_initCalled) {
        assert(false, 'This should never happen.');
        return true;
      }
      _initCalled = true;

      await _getSavedPrefs();

      if (debugLogging) {
        print('AppUpgrader: default operatingSystem: '
            '${upgraderOS.operatingSystem} ${upgraderOS.operatingSystemVersion}');
        print('AppUpgrader: operatingSystem: ${upgraderOS.operatingSystem}');
        print('AppUpgrader: '
            'isAndroid: ${upgraderOS.isAndroid}, '
            'isIOS: ${upgraderOS.isIOS}, '
            'isLinux: ${upgraderOS.isLinux}, '
            'isMacOS: ${upgraderOS.isMacOS}, '
            'isWindows: ${upgraderOS.isWindows}, '
            'isFuchsia: ${upgraderOS.isFuchsia}, '
            'isWeb: ${upgraderOS.isWeb}');
      }

      if (_packageInfo == null) {
        _packageInfo = await PackageInfo.fromPlatform();
        if (debugLogging) {
          print(
              'AppUpgrader: package info packageName: ${_packageInfo!.packageName}');
          print('AppUpgrader: package info appName: ${_packageInfo!.appName}');
          print('AppUpgrader: package info version: ${_packageInfo!.version}');
        }
      }

      _installedVersion = _packageInfo!.version;

      await _updateVersionInfo();

      // Add an observer of application events.
      WidgetsBinding.instance.addObserver(this);

      _evaluationReady = true;

      /// Trigger the stream to indicate an evaluation should be performed.
      /// The value will always be true.
      _streamController.add(true);

      return true;
    });
    return _futureInit!;
  }

  /// Remove any resources allocated.
  void dispose() {
    // Remove the observer of application events.
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Handle application events.
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    // When app has resumed from background.
    if (state == AppLifecycleState.resumed) {
      await _updateVersionInfo();

      /// Trigger the stream to indicate another evaluation should be performed.
      /// The value will always be true.
      _streamController.add(true);
    }
  }

  Future<bool> _updateVersionInfo() async {
    // If there is an appcast for this platform
    if (_isAppcastThisPlatform()) {
      if (debugLogging) {
        print('AppUpgrader: appcast is available for this platform');
      }

      final appcast = this.appcast ?? Appcast(client: client);
      await appcast.parseAppcastItemsFromUri(appcastConfig!.url!);
      if (debugLogging) {
        var count = appcast.items == null ? 0 : appcast.items!.length;
        print('AppUpgrader: appcast item count: $count');
      }
      final criticalUpdateItem = appcast.bestCriticalItem();
      final criticalVersion = criticalUpdateItem?.versionString ?? '';

      final bestItem = appcast.bestItem();
      if (bestItem != null &&
          bestItem.versionString != null &&
          bestItem.versionString!.isNotEmpty) {
        if (debugLogging) {
          print(
              'AppUpgrader: appcast best item version: ${bestItem.versionString}');
          print(
              'AppUpgrader: appcast critical update item version: ${criticalUpdateItem?.versionString}');
        }

        try {
          if (criticalVersion.isNotEmpty &&
              Version.parse(_installedVersion!) <
                  Version.parse(criticalVersion)) {
            _isCriticalUpdate = true;
          }
        } catch (e) {
          print(
              'AppUpgrader: updateVersionInfo could not parse version info $e');
          _isCriticalUpdate = false;
        }

        _appStoreVersion = bestItem.versionString;
        _appStoreListingURL = bestItem.fileURL;
        _releaseNotes = bestItem.itemDescription;
      }
    } else {
      if (_packageInfo == null || _packageInfo!.packageName.isEmpty) {
        return false;
      }

      // The  country code of the locale, defaulting to `US`.
      final country = countryCode ?? findCountryCode();
      if (debugLogging) {
        print('AppUpgrader: countryCode: $country');
      }

      // The  language code of the locale, defaulting to `en`.
      final language = languageCode ?? findLanguageCode();
      if (debugLogging) {
        print('AppUpgrader: languageCode: $language');
      }

      // Get Android version from Google Play Store, or
      // get iOS version from iTunes Store.
      if (upgraderOS.isAndroid) {
        await _getAndroidStoreVersion(country: country, language: language);
      } else if (upgraderOS.isIOS) {
        final iTunes = ITunesSearchAPI();
        iTunes.debugLogging = debugLogging;
        iTunes.client = client;
        final response = await (iTunes
            .lookupByBundleId(_packageInfo!.packageName, country: country));

        if (response != null) {
          _appStoreVersion = iTunes.version(response);
          _appStoreListingURL = iTunes.trackViewUrl(response);
          _releaseNotes ??= iTunes.releaseNotes(response);
          final mav = iTunes.minAppVersion(response);
          if (mav != null) {
            minAppVersion = mav.toString();
            if (debugLogging) {
              print('AppUpgrader: ITunesResults.minAppVersion: $minAppVersion');
            }
          }
        }
      }
    }

    return true;
  }

  /// Android info is fetched by parsing the html of the app store page.
  Future<bool?> _getAndroidStoreVersion(
      {String? country, String? language}) async {
    final id = _packageInfo!.packageName;
    final playStore = PlayStoreSearchAPI(client: client);
    playStore.debugLogging = debugLogging;
    final response =
        await (playStore.lookupById(id, country: country, language: language));
    if (response != null) {
      _appStoreVersion ??= playStore.version(response);
      _appStoreListingURL ??=
          playStore.lookupURLById(id, language: language, country: country);
      _releaseNotes ??= playStore.releaseNotes(response);
      final mav = playStore.minAppVersion(response);
      if (mav != null) {
        minAppVersion = mav.toString();
        if (debugLogging) {
          print('AppUpgrader: PlayStoreResults.minAppVersion: $minAppVersion');
        }
      }
    }

    return true;
  }

  bool _isAppcastThisPlatform() {
    if (appcastConfig == null ||
        appcastConfig!.url == null ||
        appcastConfig!.url!.isEmpty) {
      return false;
    }

    // Since this appcast config contains a URL, this appcast is valid.
    // However, if the supported OS is not listed, it is not supported.
    // When there are no supported OSes listed, they are all supported.
    var supported = true;
    if (appcastConfig!.supportedOS != null) {
      supported =
          appcastConfig!.supportedOS!.contains(upgraderOS.operatingSystem);
    }
    return supported;
  }

  bool _verifyInit() {
    if (!_initCalled) {
      throw (notInitializedExceptionMessage);
    }
    return true;
  }

  String appName() {
    _verifyInit();
    return _packageInfo?.appName ?? '';
  }

  String? currentAppStoreListingURL() => _appStoreListingURL;

  String? currentAppStoreVersion() => _appStoreVersion;

  String? currentInstalledVersion() => _installedVersion;

  String? get releaseNotes => _releaseNotes;

  String body(UpgraderMessages messages) {
    var msg = messages.message(UpgraderMessage.body)!;
    msg = msg.replaceAll('{{appName}}', appName());
    msg = msg.replaceAll(
        '{{currentAppStoreVersion}}', currentAppStoreVersion() ?? '');
    msg = msg.replaceAll(
        '{{currentInstalledVersion}}', currentInstalledVersion() ?? '');
    return msg;
  }

  /// Will show the alert dialog when it should be dispalyed.
  /// Only called by [AppUpgradeAlert] and not used by [AppUpgradeCard].
  void checkVersion({required BuildContext context}) {
    if (!_displayed) {
      final shouldDisplay = shouldDisplayUpgrade();
      if (debugLogging) {
        print(
            'AppUpgrader: shouldDisplayReleaseNotes: ${shouldDisplayReleaseNotes()}');
      }
      if (shouldDisplay) {
        _displayed = true;
        final appMessages = determineMessages(context);

        Future.delayed(const Duration(milliseconds: 0), () {
          _showDialog(
            context: context,
            title: appMessages.message(UpgraderMessage.title),
            message: body(appMessages),
            releaseNotes: shouldDisplayReleaseNotes() ? _releaseNotes : null,
            canDismissDialog: canDismissDialog,
            messages: appMessages,
          );
        });
      }
    }
  }

  /// Determine which [UpgraderMessages] object to use. It will be either the one passed
  /// to [Upgrader], or one based on the app locale.
  UpgraderMessages determineMessages(BuildContext context) {
    {
      late UpgraderMessages appMessages;
      if (messages != null) {
        appMessages = messages!;
      } else {
        String? languageCode;
        try {
          // Get the current locale in the app.
          final locale = Localizations.localeOf(context);
          // Get the current language code in the app.
          languageCode = locale.languageCode;
          if (debugLogging) {
            print('AppUpgrader: current locale: $locale');
          }
        } catch (e) {
          // ignored, really.
        }

        appMessages = UpgraderMessages(code: languageCode);
      }

      if (appMessages.languageCode.isEmpty) {
        print('AppUpgrader: error -> languageCode is empty');
      } else if (debugLogging) {
        print('AppUpgrader: languageCode: ${appMessages.languageCode}');
      }

      return appMessages;
    }
  }

  bool blocked() {
    return belowMinAppVersion() || _isCriticalUpdate;
  }

  bool shouldDisplayUpgrade() {
    final isBlocked = blocked();

    if (debugLogging) {
      print('AppUpgrader: blocked: $isBlocked');
      print('AppUpgrader: debugDisplayAlways: $debugDisplayAlways');
      print('AppUpgrader: debugDisplayOnce: $debugDisplayOnce');
      print('AppUpgrader: hasAlerted: $_hasAlerted');
    }

    // If installed version is below minimum app version, or is a critical update,
    // disable ignore and later buttons.
    if (isBlocked) {
      showIgnore = false;
      showLater = false;
    }
    bool rv = true;
    if (debugDisplayAlways || (debugDisplayOnce && !_hasAlerted)) {
      rv = true;
    } else if (!isUpdateAvailable()) {
      rv = false;
    } else if (isBlocked) {
      rv = true;
    } else if (isTooSoon() || alreadyIgnoredThisVersion()) {
      rv = false;
    }
    if (debugLogging) {
      print('AppUpgrader: shouldDisplayUpgrade: $rv');
    }

    // Call the [willDisplayUpgrade] callback when available.
    if (willDisplayUpgrade != null) {
      willDisplayUpgrade!(
          display: rv,
          minAppVersion: minAppVersion,
          releaseNote: releaseNotes,
          installedVersion: _installedVersion,
          appStoreVersion: _appStoreVersion);
    }

    return rv;
  }

  /// Is installed version below minimum app version?
  bool belowMinAppVersion() {
    var rv = false;
    if (minAppVersion != null) {
      try {
        final minVersion = Version.parse(minAppVersion!);
        final installedVersion = Version.parse(_installedVersion!);
        rv = installedVersion < minVersion;
      } catch (e) {
        if (debugLogging) {
          print(e);
        }
      }
    }
    return rv;
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted!);
    final rv = lastAlertedDuration < durationUntilAlertAgain;
    if (rv && debugLogging) {
      print('AppUpgrader: isTooSoon: true');
    }
    return rv;
  }

  bool alreadyIgnoredThisVersion() {
    final rv =
        _userIgnoredVersion != null && _userIgnoredVersion == _appStoreVersion;
    if (rv && debugLogging) {
      print('AppUpgrader: alreadyIgnoredThisVersion: true');
    }
    return rv;
  }

  bool isUpdateAvailable() {
    if (debugLogging) {
      print('AppUpgrader: appStoreVersion: $_appStoreVersion');
      print('AppUpgrader: installedVersion: $_installedVersion');
      print('AppUpgrader: minAppVersion: $minAppVersion');
    }
    if (_appStoreVersion == null || _installedVersion == null) {
      if (debugLogging) print('AppUpgrader: isUpdateAvailable: false');

      return false;
    }

    try {
      final appStoreVersion = Version.parse(_appStoreVersion!);
      final installedVersion = Version.parse(_installedVersion!);

      final available = appStoreVersion > installedVersion;
      _updateAvailable = available ? _appStoreVersion : null;
    } on Exception catch (e) {
      if (debugLogging) {
        print('AppUpgrader: isUpdateAvailable: $e');
      }
    }
    final isAvailable = _updateAvailable != null;
    if (debugLogging) print('AppUpgrader: isUpdateAvailable: $isAvailable');
    return isAvailable;
  }

  bool shouldDisplayReleaseNotes() {
    return showReleaseNotes && (_releaseNotes?.isNotEmpty ?? false);
  }

  /// Determine the current country code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `US`.
  String? findCountryCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null || locale.countryCode == null
        ? 'US'
        : locale.countryCode;
    return code;
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `en`.
  String? findLanguageCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null ? 'en' : locale.languageCode;
    return code;
  }

  void _showDialog({
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool canDismissDialog,
    required UpgraderMessages messages,
  }) {
    if (debugLogging) {
      print('AppUpgrader: showDialog title: $title');
      print('AppUpgrader: showDialog message: $message');
      print('AppUpgrader: showDialog releaseNotes: $releaseNotes');
    }

    // Save the date/time as the last time alerted.
    saveLastAlerted();

    showDialog(
      barrierDismissible: canDismissDialog,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () async => _shouldPopScope(),
            child: _alertDialog(
              title ?? '',
              message,
              releaseNotes,
              context,
              dialogStyle == UpgradeDialogStyle.cupertino,
              messages,
            ));
      },
    );
  }

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Defaults to false.
  bool _shouldPopScope() {
    if (debugLogging) {
      print('AppUpgrader: onWillPop called');
    }
    if (shouldPopScope != null) {
      final should = shouldPopScope!();
      if (debugLogging) {
        print('AppUpgrader: shouldPopScope=$should');
      }
      return should;
    }

    return false;
  }

  Widget _alertDialog(String title, String message, String? releaseNotes,
      BuildContext context, bool cupertino, UpgraderMessages messages) {
    Widget? notes;
    if (willDisplayUpgrade != null) {
      willDisplayUpgrade!(
          display: true,
          minAppVersion: minAppVersion,
          releaseNote: releaseNotes,
          installedVersion: currentInstalledVersion() ?? '',
          appStoreVersion: currentAppStoreVersion() ?? '');
    }
    if (releaseNotes != null) {
      notes = Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cupertino
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: <Widget>[
              Text(messages.message(UpgraderMessage.releaseNotes) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(releaseNotes),
            ],
          ));
    }
    final textTitle = Text(title, key: const Key('AppUpgrader.dialog.title'));
    final content = Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment:
              cupertino ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message),
            Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(messages.message(UpgraderMessage.prompt) ?? '')),
            if (notes != null) notes,
          ],
        )));
    final actions = <Widget>[
      if (showIgnore)
        _button(
            cupertino,
            messages.message(UpgraderMessage.buttonTitleIgnore),
            context,
            () => onUserIgnored(context, true),
            const TextStyle(),
            const ButtonStyle()),
      if (showLater)
        _button(
            cupertino,
            messages.message(UpgraderMessage.buttonTitleLater),
            context,
            () => onUserLater(context, true),
            const TextStyle(),
            const ButtonStyle()),
      _button(
          cupertino,
          messages.message(UpgraderMessage.buttonTitleUpdate),
          context,
          () => onUserUpdated(context, !blocked()),
          const TextStyle(),
          const ButtonStyle()),
    ];
    final customActions = <Widget>[
      if (showIgnore)
        _button(
            cupertino,
            messages.message(UpgraderMessage.buttonTitleIgnore),
            context,
            () => onUserIgnored(context, true),
            ignoreButtonTextStyle ?? const TextStyle(),
            ignoreButtonStyle ?? const ButtonStyle()),
      if (showIgnore)
        SizedBox(
          width: 10,
        ),
      if (showLater)
        _button(
            cupertino,
            messages.message(UpgraderMessage.buttonTitleLater),
            context,
            () => onUserLater(context, true),
            laterButtonTextStyle ?? const TextStyle(),
            laterButtonStyle ?? const ButtonStyle()),
      if (showLater)
        SizedBox(
          width: 10,
        ),
      _button(
          cupertino,
          messages.message(UpgraderMessage.buttonTitleUpdate),
          context,
          () => onUserUpdated(context, !blocked()),
          updateButtonTextStyle ?? const TextStyle(),
          updateButtonStyle ?? ButtonStyle()),
    ];

    return customDialog == false
        ? cupertino
            ? CupertinoAlertDialog(
                title: textTitle, content: content, actions: actions)
            : AlertDialog(
                title: textTitle,
                content: content,
                actions: actions,
              )
        : AlertDialog(
            icon: iconOrImage,
            backgroundColor:
                backgroundColor ?? Theme.of(context).dialogBackgroundColor,
            shape: customDialogShape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
            contentPadding: contentPadding,
            elevation: elevation,
            actionsAlignment: actionsAlignment,
            actionsOverflowAlignment: actionsOverflowAlignment,
            actionsOverflowButtonSpacing: actionsOverflowButtonSpacing,
            actionsOverflowDirection: actionsOverflowDirection,
            actionsPadding: actionsPadding,
            scrollable: scrollable,
            alignment: alignment,
            insetPadding: insetPadding,
            clipBehavior: clipBehavior,
            buttonPadding: buttonPadding,
            shadowColor: shadowColor,
            title: customTitle,
            content: Container(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: customContent ?? content,
                ),
                if (!isDefaultButton)
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Wrap(
                      children: customActions,
                    ),
                  )
              ]),
            ),
            // content: customContent ?? content,
            actions: isDefaultButton == true ? actions : null,
          );
  }

  Widget _button(
      bool cupertino,
      String? text,
      BuildContext context,
      VoidCallback? onPressed,
      TextStyle buttonTextStyle,
      ButtonStyle buttonStyle) {
    return cupertino
        ? CupertinoDialogAction(
            textStyle: cupertinoButtonTextStyle,
            onPressed: onPressed,
            child: Text(text ?? '', style: buttonTextStyle))
        : TextButton(
            style: buttonStyle,
            onPressed: onPressed,
            child: Text(
              text ?? '',
              style: buttonTextStyle,
            ));
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('AppUpgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onIgnore != null) {
      doProcess = onIgnore!();
    }

    if (doProcess) {
      _saveIgnored();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('AppUpgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onLater != null) {
      doProcess = onLater!();
    }

    if (doProcess) {}

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('AppUpgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onUpdate != null) {
      doProcess = onUpdate!();
    }

    if (doProcess) {
      _sendUserToAppStore();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  static Future<void> clearSavedSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('userIgnoredVersion');
    await prefs.remove('lastTimeAlerted');
    await prefs.remove('lastVersionAlerted');

    return;
  }

  void popNavigator(BuildContext context) {
    Navigator.of(context).pop();
    _displayed = false;
  }

  Future<bool> _saveIgnored() async {
    var prefs = await SharedPreferences.getInstance();

    _userIgnoredVersion = _appStoreVersion;
    await prefs.setString('userIgnoredVersion', _userIgnoredVersion ?? '');
    return true;
  }

  Future<bool> saveLastAlerted() async {
    var prefs = await SharedPreferences.getInstance();
    _lastTimeAlerted = DateTime.now();
    await prefs.setString('lastTimeAlerted', _lastTimeAlerted.toString());

    _lastVersionAlerted = _appStoreVersion;
    await prefs.setString('lastVersionAlerted', _lastVersionAlerted ?? '');

    _hasAlerted = true;
    return true;
  }

  Future<bool> _getSavedPrefs() async {
    var prefs = await SharedPreferences.getInstance();
    final lastTimeAlerted = prefs.getString('lastTimeAlerted');
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    _lastVersionAlerted = prefs.getString('lastVersionAlerted');

    _userIgnoredVersion = prefs.getString('userIgnoredVersion');

    return true;
  }

  void _sendUserToAppStore() async {
    if (_appStoreListingURL == null || _appStoreListingURL!.isEmpty) {
      if (debugLogging) {
        print('AppUpgrader: empty _appStoreListingURL');
      }
      return;
    }

    if (debugLogging) {
      print('AppUpgrader: launching: $_appStoreListingURL');
    }

    if (await canLaunchUrl(Uri.parse(_appStoreListingURL!))) {
      try {
        await launchUrl(Uri.parse(_appStoreListingURL!),
            mode: upgraderOS.isAndroid
                ? LaunchMode.externalNonBrowserApplication
                : LaunchMode.platformDefault);
      } catch (e) {
        if (debugLogging) {
          print('AppUpgrader: launch to app store failed: $e');
        }
      }
    } else {}
  }
}

class UpdateController extends Upgrader {
  UpdateController();

  String appStoreVersion = '';
}
