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

  Future<void> _loadMaidData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          final phone = userDoc.data()?['phone'];
          final maidQuery = await FirebaseFirestore.instance
              .collection('maid_applications')
              .where('phone', isEqualTo: phone)
              .where('status', isEqualTo: 'approved')
              .get();
          
          if (maidQuery.docs.isNotEmpty) {
            final maidData = maidQuery.docs.first.data();
            
            // Calculate monthly earnings
            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);
            final earnings = await FirebaseFirestore.instance
                .collection('hires')
                .where('maidId', isEqualTo: maidQuery.docs.first.id)
                .where('status', isEqualTo: 'completed')
                .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                .get();
                
            int monthlyEarnings = 0;
            for (var doc in earnings.docs) {
              monthlyEarnings += (doc.data()['amount'] as int? ?? 0);
            }
            
            setState(() {
              _isAvailable = maidData['isAvailable'] ?? true;
              _selectedEmploymentType = maidData['employmentType'] ?? 'Temporary';
              _monthlyEarnings = monthlyEarnings;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading maid data: $e');
    }
  }

  Future<void> _loadRequestHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          final phone = userDoc.data()?['phone'];
          final maidQuery = await FirebaseFirestore.instance
              .collection('maid_applications')
              .where('phone', isEqualTo: phone)
              .where('status', isEqualTo: 'approved')
              .get();
          
          if (maidQuery.docs.isNotEmpty) {
            final maidId = maidQuery.docs.first.id;
            final history = await FirebaseFirestore.instance
                .collection('requests')
                .where('maidId', isEqualTo: maidId)
                .where('status', whereIn: ['accepted', 'declined'])
                .orderBy('timestamp', descending: true)
                .limit(10)
                .get();

            setState(() {
              _requestHistory = history.docs
                  .map((doc) => {
                        ...doc.data(),
                        'id': doc.id,
                      })
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading request history: $e');
    }
  }

  void _listenToRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('requests')
          .where('maidId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _requests = snapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();
        });
      });
    }
  }

  Future<void> _updateAvailability(bool value) async {
    setState(() {
      _isAvailable = value;
    });
    // TODO: Update availability in Firestore
  }

  Future<void> _updateEmploymentType(String type) async {
    setState(() {
      _selectedEmploymentType = type;
    });
    // TODO: Update employment type in Firestore
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to privacy settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _userData = userDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    try {
      setState(() {
        _updatingLocation = true;
        _error = null;
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

      debugPrint('Getting current position...');
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');

      // Get address
      String city = '', area = '';
      try {
        debugPrint('Starting address lookup...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Address lookup timed out'),
        );

        debugPrint('Placemarks received: ${placemarks.length}');
        if (placemarks.isEmpty) {
          throw 'No address data available';
        }

        final place = placemarks.first;
        debugPrint('Placemark details: locality=${place.locality}, '
            'subLocality=${place.subLocality}, '
            'street=${place.street}, '
            'subAdministrativeArea=${place.subAdministrativeArea}');

        // Try different combinations to get the best location data
        city = place.locality ?? 
               place.subAdministrativeArea ?? 
               place.administrativeArea ??
               'Unknown City';
               
        area = place.subLocality ?? 
               place.street ?? 
               place.name ??
               'Unknown Area';
        
        debugPrint('Final location: city=$city, area=$area');
      } catch (e, stackTrace) {
        debugPrint('Error getting address: $e');
        debugPrint('Stack trace: $stackTrace');
        
        // Save basic location even if address lookup fails
        city = 'Unknown City';
        area = 'Location Set';
      }

      // Save location with minimal data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      debugPrint('Saving location data...');
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'city': city,
        'area': area,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublic': true,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'location': locationData,
      });

      debugPrint('Location data saved successfully');
      await _loadUserData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error updating location: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update location: ${e.toString()}'),
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

  Future<void> _viewLocation() async {
    try {
      final location = _userData?['location'] as Map<String, dynamic>?;
      if (location == null) {
        throw 'No location data available';
      }

      final latitude = location['latitude'] as double?;
      final longitude = location['longitude'] as double?;
      if (latitude == null || longitude == null) {
        throw 'Invalid location data';
      }

      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isEmpty) {
        throw 'No map apps found on your device';
      }

      await availableMaps.first.showMarker(
        coords: Coords(latitude, longitude),
        title: 'Your Location',
        description: '${location['area']}, ${location['city']}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      // Try to get current position as a way to check connectivity
      // This is more reliable than InternetAddress.lookup in Flutter
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      return true;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Maid Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsDialog(context),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  // TODO: Show notifications
                },
              ),
              if (_requests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      _requests.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                          onPressed: _loadUserData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF6750A4),
                                    child: const Text(
                                      'CA',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Text(
                                          'Claire Agaba',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Approved',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Earnings Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'This Month',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'UGX ${NumberFormat("#,###").format(_monthlyEarnings)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF6750A4)),
                          title: Text(
                            _userData?['location'] != null
                                ? '${_userData!['location']['area']}, ${_userData!['location']['city']}'
                                : 'Location not set',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            _userData?['location'] != null
                                ? 'Last updated: ${_formatTimestamp(_userData!['location']['timestamp'])}'
                                : 'Update your location to be visible to clients',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_userData?['location'] != null)
                                IconButton(
                                  icon: const Icon(Icons.map, color: Color(0xFF6750A4)),
                                  onPressed: _viewLocation,
                                  tooltip: 'View on map',
                                ),
                              _updatingLocation
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.refresh, color: Color(0xFF6750A4)),
                                      onPressed: _updateLocation,
                                      tooltip: 'Update location',
                                    ),
                            ],
                          ),
                        ),

                        // Requests Card
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Requests',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_requests.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_requests.length} New',
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_requests.isEmpty)
                                  const Center(
                                    child: Text(
                                      'No pending requests',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _requests.length,
                                    itemBuilder: (context, index) {
                                      final request = _requests[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(request['homeownerName'] ?? 'Unknown'),
                                          subtitle: Text(
                                            request['jobType'] ?? 'Unknown job type',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline),
                                                color: Colors.green,
                                                onPressed: () {
                                                  // TODO: Accept request
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel_outlined),
                                                color: Colors.red,
                                                onPressed: () {
                                                  // TODO: Decline request
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Availability Status Card
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: _isAvailable ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Availability Status',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _isAvailable,
                                      onChanged: _updateAvailability,
                                      activeColor: const Color(0xFF6750A4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isAvailable
                                      ? 'You are available for work'
                                      : 'You are not available for work',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Employment Type Card
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Employment Type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Select the types of work you\'re interested in',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateEmploymentType('Temporary'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: _selectedEmploymentType == 'Temporary'
                                              ? const Color(0xFF6750A4)
                                              : Colors.transparent,
                                          side: BorderSide(
                                            color: _selectedEmploymentType == 'Temporary'
                                                ? const Color(0xFF6750A4)
                                                : Colors.grey,
                                          ),
                                        ),
                                        child: Text(
                                          'Temporary',
                                          style: TextStyle(
                                            color: _selectedEmploymentType == 'Temporary'
                                                ? Colors.white
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateEmploymentType('Permanent'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: _selectedEmploymentType == 'Permanent'
                                              ? const Color(0xFF6750A4)
                                              : Colors.transparent,
                                          side: BorderSide(
                                            color: _selectedEmploymentType == 'Permanent'
                                                ? const Color(0xFF6750A4)
                                                : Colors.grey,
                                          ),
                                        ),
                                        child: Text(
                                          'Permanent',
                                          style: TextStyle(
                                            color: _selectedEmploymentType == 'Permanent'
                                                ? Colors.white
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Request History Card
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Request History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_requestHistory.isEmpty)
                                  const Center(
                                    child: Text(
                                      'No request history',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _requestHistory.length,
                                    itemBuilder: (context, index) {
                                      final request = _requestHistory[index];
                                      final status = request['status'];
                                      final isAccepted = status == 'accepted';
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(request['homeownerName'] ?? 'Unknown'),
                                          subtitle: Text(
                                            request['jobType'] ?? 'Unknown job type',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAccepted
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: isAccepted
                                                    ? Colors.green[800]
                                                    : Colors.red[800],
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return 'Just now';
  }
}
