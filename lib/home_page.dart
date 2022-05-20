import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.810332, 90.4125181),
    zoom: 15,
  );

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polyLines = <Polyline>{};
  int _polylineIdCounter = 1;

  @override
  void initState() {
    super.initState();
    _setMarker(const LatLng(23.810332, 90.4125181));
  }

  dispose() {
    _origin.dispose();
    _destination.dispose();
    _controller.future.then((GoogleMapController controller) {
      controller.dispose();
    });
    super.dispose();
  }

  _setMarker(LatLng point) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(_origin.text),
          position: point,
          icon: BitmapDescriptor.defaultMarker));
    });
  }

  _updateMarker(LatLng start, LatLng end) {
    _markers.clear();
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(_origin.text),
          position: start,
          icon: BitmapDescriptor.defaultMarker));
      _markers.add(Marker(
          markerId: MarkerId(_destination.text),
          position: end,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    });
  }

  void _setPolyline(List<PointLatLng> points) {
    _polyLines.clear();
    final String polylineIdVal = 'polyline$_polylineIdCounter';
    _polylineIdCounter++;
    _polyLines.add(Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            ///Origin Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  TextField(
                    controller: _origin,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Origin'),
                  ),
                  TextField(
                    controller: _destination,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Destination'),
                  ),

                  ///Search Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_origin.text.isNotEmpty &&
                          _destination.text.isNotEmpty) {
                        setState(() {});
                        var directions = await LocationService()
                            .getDirections(_origin.text, _destination.text);
                        _goToPlace(
                            directions['start_location']['lat'],
                            directions['start_location']['lng'],
                            directions['end_location']['lat'],
                            directions['end_location']['lng'],
                            directions['bounds_ne'],
                            directions['bounds_sw']);
                        _setPolyline(directions['polyline_decoded']);
                      }
                    },
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialPosition,
                markers: _markers,
                polylines: _polyLines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  } else {
                    return;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPlace(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
          northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
        ),
        50));
    _updateMarker(LatLng(startLat, startLng), LatLng(endLat, endLng));
  }
}
