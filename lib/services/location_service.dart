import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check and request location permissions
  static Future<bool> checkAndRequestPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current precise location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return null;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // Get last known position (faster, but may be outdated)
  static Future<Position?> getLastKnownPosition() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return null;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      return null;
    }
  }
}
