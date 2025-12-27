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
      // Properly encode the query parameter
      final trimmedQuery = query.trim();
      final searchQuery = trimmedQuery.isEmpty
          ? 'hospital'
          : '${Uri.encodeComponent(trimmedQuery)}+hospital';

      Uri url;
      if (latitude != null && longitude != null) {
        // Search with location bias for better results
        url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=10&lat=$latitude&lon=$longitude&radius=5000&addressdetails=1',
        );
      } else {
        // General search without location
        url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=10&addressdetails=1',
        );
      }

      AppLogger.log('Searching hospitals: $query');

      final response = await http
          .get(
            url,
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
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          AppLogger.log('Empty response from Nominatim');
          return [];
        }

        List<dynamic> data;
        try {
          data = json.decode(responseBody);
        } catch (e) {
          AppLogger.error('Failed to parse JSON response', e);
          return [];
        }

        if (data.isEmpty) {
          AppLogger.log('No hospitals found for query: $query');
          return [];
        }

        List<HospitalPlace> hospitals = [];

        for (var item in data) {
          try {
            String displayName = item['display_name']?.toString() ?? '';
            if (displayName.isEmpty) {
              AppLogger.log('Skipping item with empty display_name');
              continue;
            }

            // Extract hospital name (usually first part of display_name)
            // Try to get a meaningful name from the address components first
            String hospitalName = '';
            final address = item['address'] as Map<String, dynamic>?;
            if (address != null) {
              hospitalName =
                  (address['name'] ??
                          address['hospital'] ??
                          address['amenity'] ??
                          address['building'] ??
                          '')
                      .toString()
                      .trim();
            }

            // Fallback to first part of display_name if no name found
            if (hospitalName.isEmpty) {
              hospitalName = displayName.split(',').first.trim();
              if (hospitalName.isEmpty) {
                hospitalName = displayName;
              }
            }

            // Skip if we still don't have a name
            if (hospitalName.isEmpty) {
              AppLogger.log('Skipping item with no extractable name');
              continue;
            }

            // Parse coordinates
            double? lat;
            double? lon;
            if (item['lat'] != null) {
              lat = double.tryParse(item['lat'].toString());
            }
            if (item['lon'] != null) {
              lon = double.tryParse(item['lon'].toString());
            }

            hospitals.add(
              HospitalPlace(
                name: hospitalName,
                address: displayName,
                lat: lat,
                lon: lon,
              ),
            );
          } catch (e) {
            AppLogger.error('Error parsing hospital item', e);
            continue;
          }
        }

        AppLogger.log('Found ${hospitals.length} hospitals');
        return hospitals;
      } else {
        // Log non-200 status codes
        AppLogger.error(
          'PlacesService: HTTP ${response.statusCode}',
          response.body,
        );
      }
    } on SocketException catch (e) {
      // Network connectivity issue - rethrow so UI can handle it
      AppLogger.error('PlacesService: No internet connection', e);
      rethrow;
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
