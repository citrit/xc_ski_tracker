import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:developer' as developer;
import 'package:xml/xml.dart';

late Location location;
late LocationData currentLocation;

const double CAMERA_ZOOM = 16;
const LatLng SOURCE_LOCATION = LatLng(43.18530761638575, -73.88805916911608);

locationInit() async {
  location = Location();

  location.changeSettings(
      accuracy: LocationAccuracy.high, distanceFilter: 2, interval: 2000);

  bool _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  PermissionStatus _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }
  }
  //LocationData _locationData = await location.getLocation();
  //print("Initial location: $_locationData");
  location.onLocationChanged.listen((LocationData currLocation) {
    debugMsg("background location $currLocation");
    currentLocation = currLocation;
  });
}

void toggleTracking(bool turnOn) {
  if (turnOn == true) {
    debugMsg('Turn tracking on');
  } else {
    debugMsg('Turn tracking off');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    locationInit();

    return const MaterialApp(
      title: 'XC Ski Tracker',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();

  // for my drawn routes on the map
  final Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  //PolylinePoints polylinePoints;

  Icon fab = const Icon(
    Icons.check_box_outline_blank,
  );

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: SOURCE_LOCATION,
    zoom: CAMERA_ZOOM,
  );

  bool _trackingMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/img/BWPMapHeader.JPG',
                fit: BoxFit.contain,
                height: 44,
              ),
            ],
          ),
        ),
        body: GoogleMap(
          mapType: MapType.satellite,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _listTrails();
          },
          myLocationEnabled: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: fab,
          onPressed: () => setState(() {
            if (_trackingMe == false) {
              // LocationData _locationData = await location.getLocation();
              // print("Location: $_locationData");
              fab = const Icon(Icons.check_box);
            } else {
              fab = const Icon(Icons.check_box_outline_blank);
            }
            _trackingMe = !_trackingMe;
            toggleTracking(_trackingMe);
          }),
          label: const Text("Track Me"), //,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }

  // List<String> allTrails = <String>{} as List<String>;
  // void loadTrails() async {
  //   await _listTrails();
  //   allTrails.forEach((element) => debugMsg(element));
  // }

  Future _listTrails() async {
    // >> To get paths you need these 2 lines
    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // >> To get paths you need these 2 lines

    final imagePaths = manifestMap.keys
        .where((String key) => key.contains('assets/trails/'))
        .where((String key) => key.contains('.gpx'))
        .toList();

    for (var element in imagePaths) {
      debugMsg(element);
      final xmlstr = await rootBundle.loadString(element);
      final document = XmlDocument.parse(xmlstr);
      readGPX(document);
    }
  }

  void readGPX(XmlDocument document) {
    final names = document.findAllElements('name');
    names.map((node) => node.text).forEach((str) => debugMsg(str));
    // debugMsg(trailName!);
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}

void debugMsg(String msg) {
  developer.log(msg, name: 'xc-ski-tracker.info');
}
