import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:blood_linker/utils/logger.dart';

class HospitalPlace {
  final String name;
  final String address;
  final double? lat;
  final double? lon;

  HospitalPlace({
    required this.name,
    required this.address,
    this.lat,
    this.lon,
  });
}

class PlacesService {
  // Search for nearby hospitals using Nominatim (OpenStreetMap)
  static Future<List<HospitalPlace>> searchNearbyHospitals(
    String query,
    double? latitude,
    double? longitude,
  ) async {
    try {
      String url;

      if (latitude != null && longitude != null) {
        // Search with location bias for better results
        url =
            'https://nominatim.openstreetmap.org/search?q=$query+hospital&format=json&limit=10&lat=$latitude&lon=$longitude&radius=5000&addressdetails=1';
      } else {
        // General search without location
        url =
            'https://nominatim.openstreetmap.org/search?q=$query+hospital&format=json&limit=10&addressdetails=1';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'BloodLinker App', // Required by Nominatim
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<HospitalPlace> hospitals = [];

        for (var item in data) {
          String name = item['display_name'] ?? '';
          // Extract hospital name (usually first part of display_name)
          String hospitalName = name.split(',').first;

          hospitals.add(
            HospitalPlace(
              name: hospitalName,
              address: name,
              lat: item['lat'] != null ? double.tryParse(item['lat']) : null,
              lon: item['lon'] != null ? double.tryParse(item['lon']) : null,
            ),
          );
        }

        return hospitals;
      } else {
        // Log non-200 status codes
        AppLogger.error(
          'PlacesService: HTTP ${response.statusCode}',
          response.body,
        );
      }
    } on SocketException catch (e) {
      // Network connectivity issue
      AppLogger.error('PlacesService: No internet connection', e);
    } on TimeoutException catch (e) {
      // Request timeout
      AppLogger.error('PlacesService: Request timeout', e);
    } on HttpException catch (e) {
      // HTTP error
      AppLogger.error('PlacesService: HTTP error', e);
    } catch (e) {
      // Other errors
      AppLogger.error('PlacesService error', e);
    }

    return [];
  }

  // Search hospitals by name (autocomplete)
  static Future<List<HospitalPlace>> searchHospitalsByName(
    String query,
    double? latitude,
    double? longitude,
  ) async {
    if (query.length < 2) {
      return [];
    }

    return await searchNearbyHospitals(query, latitude, longitude);
  }
}
