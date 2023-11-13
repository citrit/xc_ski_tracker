import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'utils.dart';

const String trackName = "TrackingPLine";

int polyCnt = 1;
List<PatternItem> solidLine = [PatternItem.dash(10)];
List<PatternItem> dashLine = [PatternItem.dash(10), PatternItem.gap(10)];

// for my drawn routes on the map
Set<Polyline> polylines = <Polyline>{};

var descriptions = {};

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
  polylines.add(Polyline(
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

PolylineId findNearest(mp.LatLng ll, int zoomlevel) {
  PolylineId ret = const PolylineId("");
  num toler = fibonacci(23 - zoomlevel);
  // 1 * (22 - zoomlevel);
  for (var ply in polylines) {
    if (ply.polylineId.value == trackName) continue;
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
