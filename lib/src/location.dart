import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:location/location.dart' as loc;
import 'package:background_location/background_location.dart';
import 'dart:io' show Platform;

import 'package:xc_ski_tracker/src/utils.dart';

late loc.Location location;
late loc.LocationData currentLocation;

bool dialogOpened = false;

locationInit(BuildContext context) async {
  location = loc.Location();

  loc.PermissionStatus _permissionGranted = await location.hasPermission();
  if (_permissionGranted == loc.PermissionStatus.denied) {
    if (!dialogOpened) {
      dialogOpened = true;
      await showDesc(context, "XC Ski Tracker background permission",
          "XC Ski Tracker collects location data to enable the Track Me feature so it can measure your distance even when the phone is off and in your pocket. Uncheck the Track Me feature to turn off. No data is stored or uploaded.");
    }
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != loc.PermissionStatus.granted) {
      return;
    }
  }

  bool _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  //if (location.isBackgroundModeEnabled() == false) {
  //showDesc(context, "Location permissions",
  //    "XC Ski Tracker collects location data to enable the <strong>Track Me</strong> feature so it can measure your distance even when the phone is off and in your pocket. No data is stored or uploaded.");
  // location.enableBackgroundMode(enable: true);
  //}

  location.changeSettings(
      accuracy: loc.LocationAccuracy.high, distanceFilter: 2, interval: 2000);

  if (Platform.isAndroid) {
    BackgroundLocation.setAndroidNotification(
      title: "XC Ski Tracker background permission",
      message:
          "XC Ski Tracker collects location data to enable the Track Me feature so it can measure your distance even when the phone is off and in your pocket. Uncheck the Track Me feature to turn off. No data is stored or uploaded.",
      icon: "@mipmap/ic_launcher_round",
    );
    BackgroundLocation.setAndroidConfiguration(1000);
  } else if (Platform.isIOS) {
    // iOS-specific code
  }
}

void backgroundLocation(bool on) {
  if (on) {
    BackgroundLocation.startLocationService(distanceFilter: 10);
  } else {
    BackgroundLocation.stopLocationService();
  }
}
