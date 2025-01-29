import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maidmatch/screens/homeowner/location_picker_screen.dart';
import 'package:maidmatch/screens/homeowner/maid_matching_screen.dart';

class HireTemporaryMaidScreen extends StatefulWidget {
  const HireTemporaryMaidScreen({super.key});

  @override
  State<HireTemporaryMaidScreen> createState() => _HireTemporaryMaidScreenState();
}

class _HireTemporaryMaidScreenState extends State<HireTemporaryMaidScreen> {
  final List<String> _selectedServices = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String? _error;
  Map<String, double> _servicePrices = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .get();

      final services = servicesSnapshot.docs.map((doc) {
        final data = doc.data();
        _servicePrices[doc.id] = (data['price'] as num).toDouble();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'price': data['price'] as num,
          'description': data['description'] as String?,
        };
      }).toList();

      setState(() {
        _services = services;
        _isLoading = false;
      });

      debugPrint('Loaded ${services.length} services');
      for (final service in services) {
        debugPrint('Service: ${service['name']}, ID: ${service['id']}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load services. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading services: $e');
    }
  }

  double _calculateTotalBill() {
    double total = 0;
    for (String serviceId in _selectedServices) {
      total += _servicePrices[serviceId] ?? 0;
    }
    return total;
  }

  Future<void> _confirmBillAndProceed() async {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalBill = _calculateTotalBill();
    
    // Show bill confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Total Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected Services:'),
              const SizedBox(height: 8),
              ..._selectedServices.map((serviceId) {
                final service = _services.firstWhere((s) => s['id'] == serviceId);
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service['name'] as String),
                      Text('UGX ${service['price']}'),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'UGX $totalBill',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6750A4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
              ),
              child: const Text(
                'Proceed',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Proceed to location picker
    final locationSet = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (!mounted || locationSet != true) return;

    // Create temporary request
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's location
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final location = userDoc.data()?['location'] as Map<String, dynamic>?;
      if (location == null) {
        throw 'Location not found. Please try setting your location again.';
      }

      // Create the request
      final requestDoc = await FirebaseFirestore.instance
          .collection('temporaryRequests')
          .add({
        'userId': user.uid,
        'services': _selectedServices,
        'status': 'new',
        'totalAmount': totalBill,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Created request: ${requestDoc.id}');

      if (!mounted) return;

      // Navigate to maid matching screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MaidMatchingScreen(
            requestId: requestDoc.id,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Temporary Maid'),
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
                          onPressed: _loadServices,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Select Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._services.map((service) {
                            final isSelected =
                                _selectedServices.contains(service['id']);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedServices.add(service['id'] as String);
                                    } else {
                                      _selectedServices
                                          .remove(service['id'] as String);
                                    }
                                  });
                                  debugPrint(
                                      'Selected services: $_selectedServices');
                                },
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(service['name'] as String),
                                    Text(
                                      'UGX ${service['price']}',
                                      style: const TextStyle(
                                        color: Color(0xFF6750A4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: service['description'] != null
                                    ? Text(service['description'] as String)
                                    : null,
                                activeColor: const Color(0xFF6750A4),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_selectedServices.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'UGX ${_calculateTotalBill()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6750A4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedServices.isEmpty
                                  ? null
                                  : _confirmBillAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
