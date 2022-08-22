import 'package:flutter/cupertino.dart';
import 'package:location/location.dart';
import 'dart:io' show Platform;

import 'package:xc_ski_tracker/src/utils.dart';

late Location location;
//late LocationData currentLocation;

bool locationInited = false;
Future<void> initLocation(Function(LocationData) locFun) async {
  if (locationInited) return;
  location = Location();
  location.enableBackgroundMode(enable: true);

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  //LocationData _locationData;

  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }
  }

  //_locationData = await location.getLocation();

  location.onLocationChanged.listen(locFun);
  if (!await location.enableBackgroundMode(enable: true)) {
    debugMsg("Background not activated");
  }

  locationInited = true;
}

Future<void> backgroundLocation(bool on) async {
  bool retVal = await location.enableBackgroundMode(enable: on);
  if (!retVal) {
    debugMsg("Background not activated");
  }
}
