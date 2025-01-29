import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

class MaidDashboardScreen extends StatefulWidget {
  const MaidDashboardScreen({super.key});

  @override
  State<MaidDashboardScreen> createState() => _MaidDashboardScreenState();
}

class _MaidDashboardScreenState extends State<MaidDashboardScreen> {
  bool _isAvailable = true;
  String _selectedEmploymentType = 'Temporary';
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _requestHistory = [];
  int _monthlyEarnings = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  bool _updatingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadMaidData();
    _listenToRequests();
    _loadRequestHistory();
    _loadUserData();
  }

  Future<void> _updateLocation() async {
    try {
      setState(() {
        _updatingLocation = true;
      });

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

      // Get address
      String address;
      try {
        if (!await _checkInternetConnection()) {
          throw 'No internet connection';
        }

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Timeout'),
        );

        if (placemarks.isEmpty) {
          throw 'No address data';
        }

        final place = placemarks.first;
        // Only store city and area for compact display
        final components = [
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.subAdministrativeArea?.isNotEmpty ?? false) place.subAdministrativeArea,
        ].where((component) => component != null && component.isNotEmpty).toList();

        address = components.isEmpty ? 'Location set' : components.join(', ');
      } catch (e) {
        debugPrint('Error getting address: $e');
        address = 'Location set';
      }

      // Save location to user profile
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublic': true, // Make location visible to others
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'location': locationData,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      await _loadUserData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error updating location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maid Dashboard'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  children: [
                    // Profile Section
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6750A4),
                          child: Text(
                            _userData?['name']?.substring(0, 2).toUpperCase() ?? 'NA',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(_userData?['name'] ?? 'Unknown'),
                        subtitle: Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text('Approved',
                                style: TextStyle(color: Colors.green[700], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                    // Location Section - Compact
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 20, color: Color(0xFF6750A4)),
                        title: Text(
                          _userData?['location']?['address'] ?? 'No location set',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_userData?['location'] != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                icon: const Icon(Icons.map, size: 20),
                                onPressed: _viewLocation,
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              icon: _updatingLocation 
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF6750A4),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 20),
                              onPressed: _updatingLocation ? null : _updateLocation,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Other sections...
                  ],
                ),
    );
  }
}
