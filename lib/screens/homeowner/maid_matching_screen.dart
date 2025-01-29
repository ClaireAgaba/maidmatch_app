import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MaidMatchingScreen extends StatefulWidget {
  final String requestId;

  const MaidMatchingScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<MaidMatchingScreen> createState() => _MaidMatchingScreenState();
}

class _MaidMatchingScreenState extends State<MaidMatchingScreen> {
  List<Map<String, dynamic>> _availableMaids = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _requestData;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final requestDoc = await FirebaseFirestore.instance
          .collection('temporaryRequests')
          .doc(widget.requestId)
          .get();

      if (!requestDoc.exists) {
        setState(() {
          _error = 'Request not found';
          _isLoading = false;
        });
        return;
      }

      _requestData = requestDoc.data()!;
      await _findAvailableMaids();
    } catch (e) {
      setState(() {
        _error = 'Failed to load request details';
        _isLoading = false;
      });
    }
  }

  Future<void> _findAvailableMaids() async {
    try {
      if (_requestData == null) {
        throw 'Request data is missing';
      }

      final userLocation = _requestData!['location'] as Map<String, dynamic>?;
      if (userLocation == null) {
        throw 'Location data is missing';
      }

      final services = List<String>.from(_requestData!['services'] ?? []);
      if (services.isEmpty) {
        throw 'No services selected';
      }

      debugPrint('Searching for maids with services: $services');
      debugPrint('User location: $userLocation');

      // Find maids who provide these services
      final maidsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'maid')
          .where('status', isEqualTo: 'approved')
          .where('isAvailable', isEqualTo: true)
          .get();

      debugPrint('Found ${maidsQuery.docs.length} potential maids');

      final availableMaids = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (final maidDoc in maidsQuery.docs) {
        final maidData = maidDoc.data();
        final maidLocation = maidData['location'] as Map<String, dynamic>?;
        final maidServices = List<String>.from(maidData['services'] ?? []);
        
        if (maidLocation == null) {
          debugPrint('Skipping maid ${maidDoc.id}: No location data');
          continue;
        }

        // Validate location data format
        if (!maidLocation.containsKey('latitude') || 
            !maidLocation.containsKey('longitude') ||
            !maidLocation.containsKey('timestamp') ||
            !maidLocation.containsKey('isPublic')) {
          debugPrint('Skipping maid ${maidDoc.id}: Invalid location format');
          continue;
        }

        // Skip if location is not public
        if (!(maidLocation['isPublic'] as bool? ?? false)) {
          debugPrint('Skipping maid ${maidDoc.id}: Location is not public');
          continue;
        }

        // Check if location is recent (within last 30 minutes)
        final locationTimestamp = (maidLocation['timestamp'] as Timestamp).toDate();
        final locationAge = now.difference(locationTimestamp).inMinutes;
        if (locationAge > 30) {
          debugPrint('Skipping maid ${maidDoc.id}: Location is too old (${locationAge}min old)');
          continue;
        }

        // Check if maid provides at least one requested service
        final hasMatchingService = services.any((service) => maidServices.contains(service));
        if (!hasMatchingService) {
          debugPrint('Skipping maid ${maidDoc.id}: No matching services');
          continue;
        }

        try {
          // Calculate distance between homeowner and maid
          final distance = _calculateDistance(
            userLocation['latitude'] as double,
            userLocation['longitude'] as double,
            (maidLocation['latitude'] as num).toDouble(),
            (maidLocation['longitude'] as num).toDouble(),
          );

          debugPrint('Maid ${maidDoc.id} is ${distance.toStringAsFixed(2)}km away');
          debugPrint('Maid location: ${maidLocation['city']}, ${maidLocation['area']}');
          debugPrint('User location: ${userLocation['city']}, ${userLocation['area']}');

          // Only show maids within 5km for more accurate matching
          if (distance <= 5) {
            availableMaids.add({
              ...maidData,
              'id': maidDoc.id,
              'distance': distance,
              'locationAge': locationAge,
            });
            debugPrint('Added maid ${maidDoc.id} to available maids (${locationAge}min old location)');
          } else {
            debugPrint('Skipping maid ${maidDoc.id}: Too far (${distance.toStringAsFixed(2)}km)');
          }
        } catch (e) {
          debugPrint('Error calculating distance for maid ${maidDoc.id}: $e');
          continue;
        }
      }

      // Sort maids by location age and distance
      availableMaids.sort((a, b) {
        final ageA = a['locationAge'] as int;
        final ageB = b['locationAge'] as int;
        if ((ageA < 5) != (ageB < 5)) return ageA < 5 ? -1 : 1;
        
        final distanceA = a['distance'] as double;
        final distanceB = b['distance'] as double;
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _availableMaids = availableMaids;
        _isLoading = false;
      });

      debugPrint('Found ${availableMaids.length} available maids within 5km');

      if (_availableMaids.isEmpty) {
        setState(() {
          _error = 'No maids available within 5km of your location. Please try again later.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error finding available maids: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Unable to find maids: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius of the earth in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180.0);
  }

  Future<void> _selectMaid(Map<String, dynamic> maid) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update request with selected maid
      await FirebaseFirestore.instance
          .collection('temporaryRequests')
          .doc(widget.requestId)
          .update({
        'maidId': maid['id'],
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Failed to select maid. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Maids'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _availableMaids.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Maids Available',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'There are no maids available in your area for the selected services. Please try again later or modify your service selection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4),
                              ),
                              child: const Text(
                                'Go Back',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableMaids.length,
                      itemBuilder: (context, index) {
                        final maid = _availableMaids[index];
                        final distance = maid['distance'] as double;
                        final rating = (maid['rating'] as num?)?.toDouble() ?? 0.0;
                        final completedJobs = (maid['completedJobs'] as num?)?.toInt() ?? 0;
                        final skills = List<String>.from(maid['skills'] ?? []);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => _selectMaid(maid),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: maid['photoUrl'] != null
                                            ? NetworkImage(maid['photoUrl'])
                                            : null,
                                        child: maid['photoUrl'] == null
                                            ? const Icon(Icons.person, size: 30)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              maid['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: rating > 0
                                                      ? Colors.amber
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  rating > 0
                                                      ? rating.toStringAsFixed(1)
                                                      : 'New',
                                                  style: TextStyle(
                                                    color: rating > 0
                                                        ? Colors.black87
                                                        : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(
                                                  Icons.work,
                                                  size: 16,
                                                  color: completedJobs > 0
                                                      ? const Color(0xFF6750A4)
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$completedJobs jobs',
                                                  style: TextStyle(
                                                    color: completedJobs > 0
                                                        ? Colors.black87
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${distance.toStringAsFixed(1)} km away',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  if (skills.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: skills.map((skill) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6750A4)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            skill,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6750A4),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
