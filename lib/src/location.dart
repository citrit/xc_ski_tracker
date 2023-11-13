import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart';

import 'package:xc_ski_tracker/src/utils.dart';

class XCLocation {
  static Location location = Location();

  static bool get locationInited {
    bool ret = false;
    ret = GetStorage().read('locationInited') ?? false;
    return ret;
  }

  static set locationInited(bool inited) {
    debugMsg("Setting locationInited to: $inited");
    GetStorage().write('locationInited', inited);
  }

  static Future<void> initLocation(Function(LocationData) locFun) async {
    // obtain shared preferences

    debugMsg("locationInited: ${(locationInited ? "True" : "False")}");
    //if (locationInited) return;

    askForLocPermissions(locFun);
    locationInited = true;
  }

  static void askForLocPermissions(Function(LocationData) locFun) async {
    debugMsg("created location");

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        errorMsg("Background not activated");
        return;
      }
    }
    debugMsg("Location service enabled");

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        errorMsg("location permitted not granted");
        return;
      }
    }
    debugMsg("Location has permission");

    location.onLocationChanged.listen(locFun);

    if (!await location.enableBackgroundMode(enable: true)) {
      errorMsg("Background not activated");
    }
    debugMsg("Background location activated");
  }

  static Future<void> backgroundLocation(bool on) async {
    // bool retVal = await location.enableBackgroundMode(enable: on);
    // if (!retVal) {
    //   debugMsg("Background set failed: $on");
    // }
  }
}
