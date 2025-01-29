import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_launcher/map_launcher.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  Position? _currentPosition;
  String _address = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied';
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address
      await _updateAddress(position);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAddress(Position position) async {
    try {
      debugPrint('Getting address for location: ${position.latitude}, ${position.longitude}');

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Address lookup timed out. Please try again.',
      );

      debugPrint('Found ${placemarks.length} placemarks');

      if (placemarks.isEmpty) {
        setState(() {
          _address = 'Location found, but address details not available';
        });
        return;
      }

      final place = placemarks.first;
      debugPrint('Placemark details: $place');

      // Build address components, filtering out null or empty values
      final components = [
        if (place.street?.isNotEmpty ?? false) place.street,
        if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
        if (place.locality?.isNotEmpty ?? false) place.locality,
        if (place.subAdministrativeArea?.isNotEmpty ?? false) place.subAdministrativeArea,
        if (place.administrativeArea?.isNotEmpty ?? false) place.administrativeArea,
        if (place.country?.isNotEmpty ?? false) place.country,
      ].where((component) => component != null && component.isNotEmpty).toList();

      setState(() {
        if (components.isEmpty) {
          _address = 'Location found, but address details not available';
        } else {
          _address = components.join(', ');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error getting address: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        // Set a user-friendly message but don't block location saving
        _address = 'Location found, address lookup unavailable';
      });
    }
  }

  Future<void> _openMap() async {
    if (_currentPosition == null) return;

    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No map apps found on your device'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await availableMaps.first.showMarker(
        coords: Coords(_currentPosition!.latitude, _currentPosition!.longitude),
        title: 'Selected Location',
        description: _address,
      );
    } catch (e) {
      debugPrint('Error opening map: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_currentPosition == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      // Get city and area from the address
      String city = '', area = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? 
                 place.subAdministrativeArea ?? 
                 place.administrativeArea ??
                 'Unknown City';
                 
          area = place.subLocality ?? 
                 place.street ?? 
                 place.name ??
                 'Unknown Area';
        } else {
          city = 'Unknown City';
          area = 'Location Set';
        }
      } catch (e) {
        debugPrint('Error getting address details: $e');
        city = 'Unknown City';
        area = 'Location Set';
      }

      // Save location data in standardized format
      final locationData = {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'city': city,
        'area': area,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublic': true,
      };

      debugPrint('Saving location data: $locationData');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'location': locationData,
      });

      debugPrint('Location saved successfully');

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Error saving location: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to save location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Location'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _getCurrentLocation,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF6750A4)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Current Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _getCurrentLocation,
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refresh Location',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _address.isEmpty ? 'Getting address...' : _address,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _address.isEmpty ? Colors.grey : null,
                                ),
                              ),
                              if (_currentPosition != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _currentPosition != null ? _openMap : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text(
                          'View on Map',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _currentPosition != null ? _saveLocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save Location',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
