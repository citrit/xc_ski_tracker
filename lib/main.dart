import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:developer' as developer;
import 'package:xml2json/xml2json.dart';
import 'package:flutter_html/flutter_html.dart';

const double CAMERA_ZOOM = 14;
const LatLng SOURCE_LOCATION = LatLng(43.18530761638575, -73.88805916911608);
const String _trackName = "TrackingPLine";
late loc.Location location;
late loc.LocationData currentLocation;

List<LatLng> trackPts = [];

locationInit() async {
  location = loc.Location();

  bool _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  loc.PermissionStatus _permissionGranted = await location.hasPermission();
  if (_permissionGranted == loc.PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != loc.PermissionStatus.granted) {
      return;
    }
  }

  location.changeSettings(
      accuracy: loc.LocationAccuracy.high, distanceFilter: 2, interval: 2000);
  location.enableBackgroundMode(enable: true);
}

Text _trackLabel = const Text("Track Me");

void toggleTracking(bool turnOn) {
  if (turnOn == true) {
    _polylines = _polylines.union({
      Polyline(
          width: 8,
          polylineId: const PolylineId(_trackName),
          visible: true,
          //mp.LatLng is List<mp.LatLng>
          points: trackPts,
          color: nameToColor["TrackMe"]!)
    });
    debugMsg('Turn tracking on');
  } else {
    debugMsg('Turn tracking off');
    _polylines.removeWhere((el) => el.polylineId.value == _trackName);
    trackPts.clear();
    _trackLabel = const Text("Track Me");
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

// for my drawn routes on the map
Set<Polyline> _polylines = <Polyline>{};

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();

  //PolylinePoints polylinePoints;

  Icon fab = const Icon(
    Icons.check_box_outline_blank,
  );

  bool _trackingMe = false;

  var descriptions = {};

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
    location.onLocationChanged.listen((loc.LocationData currLoc) {
      debugMsg("background location $currLoc");
      currentLocation = currLoc;
      if (_trackingMe) {
        trackPts.add(LatLng(currLoc.latitude!, currLoc.longitude!));
        setState(() {
          _trackLabel = Text("Distance: " + formatLength(trackPts));
        });
      }
    });
    var _brookhaven = const CameraPosition(
        target: SOURCE_LOCATION, zoom: CAMERA_ZOOM, bearing: 0, tilt: 0);
    return Scaffold(
        appBar: MediaQuery.of(context).orientation == Orientation.landscape
            ? null // show nothing in lanscape mode
            : appBar,
        body: GoogleMap(
          mapType: MapType.satellite,
          initialCameraPosition: _brookhaven,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _listTrails();
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
              _showDesc(descriptions[plyId.value]);
            }
          },
          polylines: _polylines,
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

  PolylineId findNearest(mp.LatLng ll, int zoomlevel) {
    PolylineId ret = const PolylineId("");
    num toler = fibonacci(23 - zoomlevel);
    // 1 * (22 - zoomlevel);
    for (var ply in _polylines) {
      if (ply.polylineId.value == _trackName) continue;
      List<mp.LatLng>? mpoly = [];
      for (var el in ply.points) {
        mpoly.add(mp.LatLng(el.latitude, el.longitude));
      }
      if (mp.PolygonUtil.isLocationOnPath(ll, mpoly, ply.geodesic,
          tolerance: toler)) {
        ret = ply.polylineId;
        break;
      }
    }
    return ret;
  }

  Future _listTrails() async {
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

  int polyCnt = 1;
  List<PatternItem> solidLine = [PatternItem.dash(10)];
  List<PatternItem> dashLine = [PatternItem.dash(10), PatternItem.gap(10)];

  void readGPX(String jsonString, String lcolor) {
    var data = jsonDecode(jsonString);
    var gpx = data['gpx'];
    var tname = gpx['trk']['name']['\$t'];
    var desc = gpx['trk']['desc']['__cdata'];
    var trkPts = gpx['trk']['trkseg']['trkpt'];

    List<LatLng> poly = [];
    for (var pt in trkPts) {
      poly.add(LatLng(double.parse(pt['lat']), double.parse(pt['lon'])));
      //debugMsg("Pt: ${pt['lat']}, ${pt['lon']} ");
    }
    polyCnt += 1;
    tname += (polyCnt).toString();
    descriptions[tname] = desc;
    _polylines.add(Polyline(
        // onTap: () {
        //   debugMsg("Clicked on $tname");
        //   _showDesc(desc);
        // },
        patterns: ((tname.contains("Snowshoe")) ? dashLine : solidLine),
        width: 3,
        polylineId: PolylineId(tname),
        visible: true,
        //mp.LatLng is List<mp.LatLng>
        points: poly,
        color: nameToColor[lcolor]!));
    debugMsg("Creating track: $tname");
  }

  _showDesc(String desc) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Trail Information'),
        content: Html(data: desc),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}

Map<String, Color> nameToColor = {
  'Red': Colors.red,
  'Orange': Colors.orange,
  'Yellow': Colors.yellow,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Indigo': Colors.indigo,
  'White': Colors.white,
  'Magenta': Colors.purpleAccent,
  'Plum': Colors.purple,
  'TrackMe': Colors.blueAccent
};

void debugMsg(String msg) {
  developer.log(msg, name: 'xc-ski-tracker.info');
}

int fibonacci(int n) => n <= 2 ? 1 : fibonacci(n - 2) + fibonacci(n - 1);
