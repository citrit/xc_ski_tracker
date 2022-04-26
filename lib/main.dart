import 'dart:async';
import 'dart:convert';

import 'package:background_location/background_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:xml2json/xml2json.dart';
import 'src/location.dart';
import 'src/utils.dart';
import 'src/trails.dart';

const double cameraZoom = 14;
const LatLng cameraLocation = LatLng(43.18530761638575, -73.88805916911608);

List<LatLng> trackPts = [];

Text _trackLabel = const Text("Track Me");

void toggleTracking(bool turnOn) {
  backgroundLocation(turnOn);

  if (turnOn == true) {
    polylines = polylines.union({
      Polyline(
          width: 8,
          polylineId: const PolylineId(trackName),
          visible: true,
          //mp.LatLng is List<mp.LatLng>
          points: trackPts,
          color: nameToColor["TrackMe"]!)
    });
    debugMsg('Turn tracking on');
  } else {
    debugMsg('Turn tracking off');
    polylines.removeWhere((el) => el.polylineId.value == trackName);
    trackPts.clear();
    _trackLabel = const Text("Track Me");
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  build(BuildContext context) {
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

  //PolylinePoints polylinePoints;

  Icon fab = const Icon(
    Icons.check_box_outline_blank,
  );

  bool _trackingMe = false;

  bool dialogOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => locationInit(context));
  }

  String formatLength(List<LatLng> line) {
    List<mp.LatLng>? mpoly = [];
    for (var el in trackPts) {
      mpoly.add(mp.LatLng(el.latitude, el.longitude));
    }
    num dist = mp.SphericalUtil.computeLength(mpoly);
    String output;
    if (dist > 100) {
      output = (dist / 1000).toStringAsFixed(1) + ' km';
    } else {
      output = dist.toStringAsFixed(1) + ' m';
    }
    return output;
  }

  listTrails() async {
    // >> To get paths you need these 2 lines
    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // >> To get paths you need these 2 lines

    final imagePaths = manifestMap.keys
        .where((String key) => key.contains('assets/trails/'))
        .where((String key) => key.contains('.gpx'))
        .toList();

    final Xml2Json xml2Json = Xml2Json();

    for (var element in imagePaths) {
      //debugMsg(element);
      final xmlstr = await rootBundle.loadString(element);
      // final document = XmlDocument.parse(xmlstr);
      xml2Json.parse(xmlstr);
      var jsondata = xml2Json.toGData();
      readGPX(jsondata, element.split('-')[1].split('.')[0]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget appBar = AppBar(
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
    );

    BackgroundLocation.getLocationUpdates((location) {
      debugMsg("Location: " +
          location.longitude.toString() +
          ", " +
          location.latitude.toString());
      trackPts.add(LatLng(location.latitude!, location.longitude!));
      setState(() {
        _trackLabel = Text("Distance: " + formatLength(trackPts));
      });
    });

    // location.onLocationChanged.listen((LocationData currLoc) {
    //   debugMsg("background location $currLoc");
    //   currentLocation = currLoc;
    //   if (_trackingMe) {
    //     trackPts.add(LatLng(currLoc.latitude!, currLoc.longitude!));
    //     setState(() {
    //       _trackLabel = Text("Distance: " + formatLength(trackPts));
    //     });
    //   }
    // });
    var _brookhaven = const CameraPosition(
        target: cameraLocation, zoom: cameraZoom, bearing: 0, tilt: 0);
    return Scaffold(
        appBar: MediaQuery.of(context).orientation == Orientation.landscape
            ? null // show nothing in lanscape mode
            : appBar,
        body: GoogleMap(
          mapType: MapType.satellite,
          initialCameraPosition: _brookhaven,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            listTrails();
          },
          onTap: (latlng) async {
            //debugMsg("Taped: $latlng");
            final GoogleMapController controller = await _controller.future;
            int zl = (await controller.getZoomLevel()).round();
            var plyId =
                findNearest(mp.LatLng(latlng.latitude, latlng.longitude), zl);
            if (plyId.value == "") {
              debugMsg(" Zoom: $zl  Tol: " +
                  fibonacci(23 - zl).toString() +
                  " " +
                  "Nothing near by");
            } else {
              showDesc(context, 'Trail Information', descriptions[plyId.value]);
            }
          },
          polylines: polylines,
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
          label: _trackLabel, //,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}
