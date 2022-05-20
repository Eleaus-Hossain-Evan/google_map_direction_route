import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class LocationService {
  final String apiKey = 'AIzaSyA0y82hvYQpAYdusasMnFiQOgy-D5rPYWA';

  Future<Map<String, dynamic>> getDirections(
      String origin, String destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';
    try {
      var response = await http.get(Uri.parse(url));
      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == "OK") {
        var result = {
          'bounds_ne': jsonData['routes'][0]['bounds']['northeast'],
          'bounds_sw': jsonData['routes'][0]['bounds']['southwest'],
          'start_location': jsonData['routes'][0]['legs'][0]['start_location'],
          'end_location': jsonData['routes'][0]['legs'][0]['end_location'],
          'polyline': jsonData['routes'][0]['overview_polyline']['points'],
          'polyline_decoded': PolylinePoints().decodePolyline(
              jsonData['routes'][0]['overview_polyline']['points'])
        };
        return result;
      } else {
        var result = {
          'bounds_ne': "",
          'bounds_sw': "",
          'start_location': 0,
          'end_location': 0,
          'polyline': "",
          'polyline_decoded': "",
        };
        return result;
      }
    } catch (e) {
      debugPrint(e.toString());

      return {};
    }
  }
}
