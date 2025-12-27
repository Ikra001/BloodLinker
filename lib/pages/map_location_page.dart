import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;

import 'package:blood_linker/constants.dart';
import 'package:blood_linker/services/location_service.dart';
import 'package:blood_linker/services/places_service.dart';
import 'package:blood_linker/utils/logger.dart';

class MapLocationPage extends StatefulWidget {
  const MapLocationPage({super.key});

  @override
  State<MapLocationPage> createState() => _MapLocationPageState();
}

class _MapLocationPageState extends State<MapLocationPage>
    with OSMMixinObserver {
  final MapController controller = MapController(
    initPosition: GeoPoint(latitude: 0, longitude: 0),
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Position? _currentPosition;
  GeoPoint? _currentLocationPoint;
  GeoPoint? _selectedPoint;
  HospitalPlace? _selectedHospital;
  String? _selectedLocationName;
  List<HospitalPlace> _hospitalResults = [];
  GeoPoint? _previousSelectedMarkerPoint;
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isLoadingLocationName = false;
  bool _mapIsReady = false;
  String? _networkError;

  Timer? _searchDebounceTimer;
  String _lastSearchQuery = '';

  // Reusable marker icons
  static final MarkerIcon _selectedMarkerIcon = MarkerIcon(
    icon: Icon(Icons.location_on, color: Colors.red, size: 80),
  );

  // Blue circular marker for current location (Google Maps style)
  static final MarkerIcon _currentLocationMarkerIcon = MarkerIcon(
    icon: Icon(Icons.my_location, color: Colors.blue, size: 60),
  );

  @override
  void initState() {
    super.initState();
    controller.addObserver(this);
    // Don't initialize here - wait for map to be ready
    // mapIsReady will handle initialization
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    controller.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted || position == null) return;

      final currentPoint = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _currentLocationPoint = currentPoint;
      });

      // Initialize map if ready
      if (_mapIsReady) {
        await _initializeMapWithLocation(currentPoint);
      }
    } catch (e) {
      AppLogger.error('Error initializing map', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Initialize map with location (called when both map and location are ready)
  Future<void> _initializeMapWithLocation(GeoPoint point) async {
    try {
      AppLogger.log(
        'Initializing map with location: ${point.latitude}, ${point.longitude}',
      );
      await controller.moveTo(point);
      await _addCurrentLocationMarker(point);
      await _loadNearbyHospitals(point);
      AppLogger.log('Map initialization complete');
    } catch (e) {
      AppLogger.error('Error in _initializeMapWithLocation', e);
    }
  }

  // Add blue circular marker for current location
  Future<void> _addCurrentLocationMarker(GeoPoint point) async {
    try {
      // Remove previous current location marker if exists
      if (_currentLocationPoint != null) {
        try {
          await controller.removeMarker(_currentLocationPoint!);
        } catch (e) {
          // Ignore if marker doesn't exist
        }
      }

      // Add new current location marker
      await controller.addMarker(point, markerIcon: _currentLocationMarkerIcon);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadNearbyHospitals(GeoPoint center) async {
    try {
      final hospitals = await PlacesService.searchNearbyHospitals(
        '',
        center.latitude,
        center.longitude,
      );

      AppLogger.log('Loaded ${hospitals.length} hospitals near location');

      if (mounted && hospitals.isNotEmpty) {
        for (var hospital in hospitals) {
          if (hospital.lat != null && hospital.lon != null) {
            try {
              await controller.addMarker(
                GeoPoint(latitude: hospital.lat!, longitude: hospital.lon!),
                markerIcon: MarkerIcon(
                  icon: Icon(
                    Icons.local_hospital,
                    color: Constants.primaryColor,
                    size: 40,
                  ),
                ),
              );
            } catch (e) {
              AppLogger.error('Error adding hospital marker', e);
            }
          }
        }
      }
    } on SocketException catch (e) {
      AppLogger.error('Error loading nearby hospitals - Network error', e);
      if (mounted) {
        setState(() {
          _networkError =
              'No internet connection. Nearby hospitals cannot be loaded.';
        });
      }
    } catch (e) {
      AppLogger.error('Error loading nearby hospitals', e);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous debounce timer
    _searchDebounceTimer?.cancel();

    // Clear results immediately if query is too short
    if (query.length < 2) {
      setState(() {
        _hospitalResults = [];
        _isSearching = false;
      });
      return;
    }

    // Don't search if query hasn't changed
    if (query == _lastSearchQuery) {
      return;
    }

    // Set loading state
    setState(() {
      _isSearching = true;
    });

    // Debounce: wait 800ms after user stops typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      // Only search if query is still valid and hasn't changed
      final currentQuery = _searchController.text.trim();
      if (currentQuery.length >= 2 && currentQuery == query) {
        _lastSearchQuery = currentQuery;

        try {
          AppLogger.log('Searching for hospitals: $currentQuery');

          // Clear previous network error
          if (mounted) {
            setState(() {
              _networkError = null;
            });
          }

          final results = await PlacesService.searchHospitalsByName(
            currentQuery,
            _currentPosition?.latitude,
            _currentPosition?.longitude,
          );

          AppLogger.log('Found ${results.length} hospitals');

          // Sort by distance from current location
          final sortedResults = _sortHospitalsByDistance(results);

          // Only update if query hasn't changed during search
          if (mounted && _searchController.text.trim() == currentQuery) {
            setState(() {
              _hospitalResults = sortedResults;
              _isSearching = false;
              _networkError = null;
            });
          }
        } on SocketException catch (e) {
          AppLogger.error('Error searching hospitals - Network error', e);
          if (mounted && _searchController.text.trim() == currentQuery) {
            setState(() {
              _hospitalResults = [];
              _isSearching = false;
              _networkError =
                  'No internet connection. Please check your network and try again.';
            });
          }
        } catch (e) {
          AppLogger.error('Error searching hospitals', e);
          if (mounted && _searchController.text.trim() == currentQuery) {
            setState(() {
              _hospitalResults = [];
              _isSearching = false;
              _networkError = 'Failed to search hospitals. Please try again.';
            });
          }
        }
      } else if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _selectHospital(HospitalPlace hospital) async {
    if (hospital.lat != null && hospital.lon != null) {
      final point = GeoPoint(latitude: hospital.lat!, longitude: hospital.lon!);
      await _setSelectedLocation(point, hospital, hospital.name);
      await controller.moveTo(point);
      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() {
        _hospitalResults = [];
      });
    }
  }

  Future<void> _onMapLongPress(GeoPoint point) async {
    // Immediately add marker and set location (optimistic update)
    await _setSelectedLocation(point, null, 'Selected Location');

    // Then fetch descriptive name in background (non-blocking)
    _updateLocationNameInBackground(point);
  }

  // Update location name in background without blocking UI
  Future<void> _updateLocationNameInBackground(GeoPoint point) async {
    if (!mounted) return;

    // Set loading state
    final isSelectedPoint =
        _selectedPoint?.latitude == point.latitude &&
        _selectedPoint?.longitude == point.longitude;

    if (isSelectedPoint) {
      setState(() {
        _isLoadingLocationName = true;
      });
    }

    try {
      // Find nearby hospital for descriptive name
      final nearbyHospital = await _findNearestHospital(point);

      // Get descriptive name if no hospital found
      String locationName = nearbyHospital?.name ?? 'Selected Location';
      if (nearbyHospital == null) {
        locationName = await _getLocationName(point);
      }

      AppLogger.log('Location name resolved: $locationName');

      // Only update if this is still the selected point
      if (mounted && isSelectedPoint) {
        setState(() {
          _selectedHospital = nearbyHospital;
          _selectedLocationName = locationName;
          _isLoadingLocationName = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error updating location name', e);
      if (mounted && isSelectedPoint) {
        setState(() {
          _selectedLocationName = 'Selected Location';
          _isLoadingLocationName = false;
        });
      }
    }
  }

  // Find the nearest hospital to a given point
  Future<HospitalPlace?> _findNearestHospital(GeoPoint point) async {
    try {
      // Search for hospitals near the point
      final hospitals = await PlacesService.searchNearbyHospitals(
        '',
        point.latitude,
        point.longitude,
      );

      if (hospitals.isEmpty) return null;

      // Find the closest hospital (within 500 meters)
      HospitalPlace? nearest;
      double minDistance = double.infinity;

      for (var hospital in hospitals) {
        if (hospital.lat != null && hospital.lon != null) {
          final distance = _calculateDistance(
            point.latitude,
            point.longitude,
            hospital.lat!,
            hospital.lon!,
          );

          // If within 500 meters, consider it
          if (distance < 500 && distance < minDistance) {
            minDistance = distance;
            nearest = hospital;
          }
        }
      }

      return nearest;
    } catch (e) {
      return null;
    }
  }

  // Sort hospitals by distance from current location
  List<HospitalPlace> _sortHospitalsByDistance(List<HospitalPlace> hospitals) {
    if (_currentPosition == null) {
      return hospitals; // Can't sort without current location
    }

    // Create a list with distance information
    final hospitalsWithDistance = hospitals.map((hospital) {
      double? distance;
      if (hospital.lat != null && hospital.lon != null) {
        distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          hospital.lat!,
          hospital.lon!,
        );
      }
      return MapEntry(hospital, distance);
    }).toList();

    // Sort by distance (null distances go to end)
    hospitalsWithDistance.sort((a, b) {
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;
      return a.value!.compareTo(b.value!);
    });

    return hospitalsWithDistance.map((e) => e.key).toList();
  }

  // Calculate distance between two points in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        (dLat / 2) * (dLat / 2) +
        _toRadians(lat1) * _toRadians(lat2) * (dLon / 2) * (dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Format distance in a user-friendly way
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  // Get a descriptive name for a location using reverse geocoding
  Future<String> _getLocationName(GeoPoint point) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&addressdetails=1',
            ),
            headers: {'User-Agent': 'BloodLinker App'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try to get a meaningful name
          final name =
              address['name'] ??
              address['road'] ??
              address['suburb'] ??
              address['city'] ??
              address['town'] ??
              address['village'] ??
              'Selected Location';
          return name.toString();
        }
      }
    } on TimeoutException catch (e) {
      // Request timeout
      AppLogger.error('_getLocationName: Request timeout', e);
    } on SocketException catch (e) {
      // Network connectivity issue
      AppLogger.error('_getLocationName: No internet connection', e);
    } catch (e) {
      // Other errors
      AppLogger.error('_getLocationName error', e);
    }

    // Return coordinates as fallback when network fails
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  Future<void> _onMapTap(GeoPoint point) async {
    // Immediately add marker and set location (optimistic update)
    await _setSelectedLocation(point, null, 'Selected Location');

    // Then fetch descriptive name in background (non-blocking)
    _updateLocationNameInBackground(point);
  }

  // Common method to set selected location and add marker
  Future<void> _setSelectedLocation(
    GeoPoint point,
    HospitalPlace? hospital,
    String locationName,
  ) async {
    // Remove previous selected marker if it exists
    if (_previousSelectedMarkerPoint != null) {
      try {
        await controller.removeMarker(_previousSelectedMarkerPoint!);
      } catch (e) {
        // Ignore - marker might not exist
      }
    }

    setState(() {
      _selectedPoint = point;
      _selectedHospital = hospital;
      _selectedLocationName = locationName;
      _previousSelectedMarkerPoint = point;
    });

    // Add new selected marker (only one marker)
    try {
      await controller.addMarker(point, markerIcon: _selectedMarkerIcon);
    } catch (e) {
      // Ignore errors
    }
  }

  void _confirmSelection() {
    if (_selectedPoint != null) {
      Navigator.pop(context, {
        'latitude': _selectedPoint!.latitude,
        'longitude': _selectedPoint!.longitude,
        'hospitalName': _selectedHospital?.name ?? _selectedLocationName ?? '',
        'address': _selectedHospital?.address ?? _selectedLocationName ?? '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPoint != null)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          OSMFlutter(
            controller: controller,
            osmOption: OSMOption(
              userTrackingOption: UserTrackingOption(enableTracking: false),
              zoomOption: const ZoomOption(
                initZoom: 15.0,
                minZoomLevel: 5.0,
                maxZoomLevel: 19.0,
                stepZoom: 1.0,
              ),
            ),
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            onMapIsReady: (isReady) async {
              if (isReady && mounted) {
                AppLogger.log('Map is ready, initializing...');
                setState(() {
                  _mapIsReady = true;
                });
                // Initialize map with location
                await _initializeMap();
              }
            },
            onGeoPointClicked: (point) {
              // Single tap - select existing marker or point
              _onMapTap(point);
            },
          ),

          // Search Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search hospitals...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _initializeMap,
                              tooltip: 'Get current location',
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (_networkError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _networkError!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.red.shade700,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _networkError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_hospitalResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _hospitalResults.length,
                        itemBuilder: (context, index) {
                          final hospital = _hospitalResults[index];
                          final distance =
                              _currentPosition != null &&
                                  hospital.lat != null &&
                                  hospital.lon != null
                              ? _calculateDistance(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  hospital.lat!,
                                  hospital.lon!,
                                )
                              : null;

                          return ListTile(
                            leading: const Icon(
                              Icons.local_hospital,
                              color: Constants.primaryColor,
                            ),
                            title: Text(
                              hospital.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (distance != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _formatDistance(distance),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Constants.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            dense: true,
                            onTap: () => _selectHospital(hospital),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),

          // Selected location info
          if (_selectedPoint != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedHospital?.name ??
                                  _selectedLocationName ??
                                  'Selected Location',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_isLoadingLocationName)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_selectedHospital != null) ...[
                        Text(
                          _selectedHospital!.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                          'Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColor,
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  // ignore: must_call_super
  Future<void> mapIsReady(bool isReady) async {
    // onMapIsReady callback in widget already handles this
    // This override is kept for OSMMixinObserver compliance
    // Note: Cannot call super as method is abstract
  }

  @override
  // ignore: must_call_super
  Future<void> onLongTap(GeoPoint position) async {
    // Long press detected - add marker at this position
    await _onMapLongPress(position);
    // Note: Cannot call super as method is abstract
  }

  @override
  // ignore: must_call_super
  void onRoadTap(RoadInfo road) {
    // Handle road tap if needed
    // Note: Cannot call super as method is abstract
  }

  @override
  // ignore: must_call_super
  void onLocationChanged(GeoPoint geoPoint) {
    // Handle location change if needed
    // Note: Cannot call super as method is abstract
  }
}
