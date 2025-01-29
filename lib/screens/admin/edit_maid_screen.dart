import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class EditMaidScreen extends StatefulWidget {
  final String maidId;

  const EditMaidScreen({
    super.key,
    required this.maidId,
  });

  @override
  State<EditMaidScreen> createState() => _EditMaidScreenState();
}

class _EditMaidScreenState extends State<EditMaidScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic>? _maidData;

  // Bio Data
  final _surnameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Female';

  // Personal Info
  final _phoneController = TextEditingController();
  String _nationality = 'Uganda';
  final _tribeController = TextEditingController();
  String _maritalStatus = 'Single';
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinContactController = TextEditingController();

  // Location
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  GoogleMapController? _mapController;

  // Skills
  String _educationLevel = 'Primary';
  final List<String> _selectedLanguages = [];
  final List<String> _selectedServices = [];

  // Medical History
  bool _hasAllergies = false;
  bool _hasChronicDiseases = false;
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _otherMedicalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaidData();
  }

  Future<void> _loadMaidData() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.maidId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maid not found')),
        );
        return;
      }

      setState(() {
        _maidData = doc.data();
        
        // Bio Data
        _surnameController.text = _maidData?['firstName'] ?? '';
        _lastNameController.text = _maidData?['lastName'] ?? '';
        _dateOfBirth = _maidData?['dateOfBirth'] != null
            ? DateTime.parse(_maidData!['dateOfBirth'])
            : null;
        _gender = _maidData?['gender'] ?? 'Female';

        // Personal Info
        _phoneController.text = (_maidData?['phone'] ?? '').toString();
        _nationality = _maidData?['nationality'] ?? 'Uganda';
        _tribeController.text = _maidData?['tribe'] ?? '';
        _maritalStatus = _maidData?['maritalStatus'] ?? 'Single';
        _nextOfKinNameController.text = _maidData?['nextOfKin']?['name'] ?? '';
        _nextOfKinContactController.text = (_maidData?['nextOfKin']?['contact'] ?? '').toString();

        // Location
        final location = _maidData?['location'];
        if (location != null) {
          _selectedLocation = LatLng(
            location['latitude'] ?? 0,
            location['longitude'] ?? 0,
          );
          _selectedAddress = location['address'] ?? '';
        }

        // Skills
        _educationLevel = _maidData?['educationLevel'] ?? 'Primary';
        _selectedLanguages.clear();
        _selectedLanguages.addAll(
          List<String>.from(_maidData?['languages'] ?? []),
        );
        _selectedServices.clear();
        _selectedServices.addAll(
          List<String>.from(_maidData?['services'] ?? []),
        );

        // Medical History
        final medicalHistory = _maidData?['medicalHistory'];
        if (medicalHistory != null) {
          _hasAllergies = medicalHistory['hasAllergies'] ?? false;
          _hasChronicDiseases = medicalHistory['hasChronicDiseases'] ?? false;
          _allergiesController.text = medicalHistory['allergies'] ?? '';
          _chronicDiseasesController.text = medicalHistory['chronicDiseases'] ?? '';
          _otherMedicalInfoController.text = medicalHistory['otherInfo'] ?? '';
        }

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading maid data: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading maid data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Maid'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bio Data Section
              const Text(
                'Bio Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date of Birth'),
                subtitle: Text(
                  _dateOfBirth != null
                      ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateOfBirth = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Female', 'Male'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gender = value);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Personal Info Section
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _nationality,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  border: OutlineInputBorder(),
                ),
                items: ['Uganda', 'Kenya', 'Tanzania', 'Rwanda'].map((country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _nationality = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tribeController,
                decoration: const InputDecoration(
                  labelText: 'Tribe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                ),
                items: ['Single', 'Married', 'Divorced', 'Widowed'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _maritalStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nextOfKinNameController,
                decoration: const InputDecoration(
                  labelText: 'Next of Kin Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nextOfKinContactController,
                decoration: const InputDecoration(
                  labelText: 'Next of Kin Contact',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Location Section
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          onMapCreated: (controller) => _mapController = controller,
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation ?? const LatLng(0.3476, 32.5825),
                            zoom: 15,
                          ),
                          markers: _selectedLocation != null ? {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedLocation!,
                              draggable: true,
                              onDragEnd: (newPosition) {
                                setState(() => _selectedLocation = newPosition);
                                _getAddressFromLatLng(newPosition);
                              },
                            ),
                          } : {},
                          onTap: (position) {
                            setState(() => _selectedLocation = position);
                            _getAddressFromLatLng(position);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_selectedAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Skills Section
              const Text(
                'Skills & Education',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _educationLevel,
                decoration: const InputDecoration(
                  labelText: 'Education Level',
                  border: OutlineInputBorder(),
                ),
                items: ['Primary', 'Secondary', 'Certificate', 'Diploma', 'Degree'].map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _educationLevel = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Languages'),
              Wrap(
                spacing: 8,
                children: ['English', 'Swahili', 'Luganda', 'Runyankole'].map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLanguages.add(lang);
                        } else {
                          _selectedLanguages.remove(lang);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Services'),
              Wrap(
                spacing: 8,
                children: [
                  'Cleaning',
                  'Cooking',
                  'Laundry',
                  'Childcare',
                  'Elderly Care',
                  'Gardening'
                ].map((service) {
                  final isSelected = _selectedServices.contains(service);
                  return FilterChip(
                    label: Text(service),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Medical History Section
              const Text(
                'Medical History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Has Allergies'),
                value: _hasAllergies,
                onChanged: (value) {
                  setState(() => _hasAllergies = value);
                },
              ),
              if (_hasAllergies) ...[
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies Details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              SwitchListTile(
                title: const Text('Has Chronic Diseases'),
                value: _hasChronicDiseases,
                onChanged: (value) {
                  setState(() => _hasChronicDiseases = value);
                },
              ),
              if (_hasChronicDiseases) ...[
                TextFormField(
                  controller: _chronicDiseasesController,
                  decoration: const InputDecoration(
                    labelText: 'Chronic Diseases Details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _otherMedicalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Other Medical Information',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton(
                onPressed: _updateMaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateMaid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.maidId)
          .update({
        'firstName': _surnameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'gender': _gender,
        'phone': _phoneController.text.trim(),
        'nationality': _nationality,
        'tribe': _tribeController.text.trim(),
        'maritalStatus': _maritalStatus,
        'nextOfKin': {
          'name': _nextOfKinNameController.text.trim(),
          'contact': _nextOfKinContactController.text.trim(),
        },
        'location': {
          'latitude': _selectedLocation?.latitude,
          'longitude': _selectedLocation?.longitude,
          'address': _selectedAddress,
        },
        'educationLevel': _educationLevel,
        'languages': _selectedLanguages,
        'services': _selectedServices,
        'medicalHistory': {
          'hasAllergies': _hasAllergies,
          'allergies': _hasAllergies ? _allergiesController.text.trim() : '',
          'hasChronicDiseases': _hasChronicDiseases,
          'chronicDiseases': _hasChronicDiseases ? _chronicDiseasesController.text.trim() : '',
          'otherInfo': _otherMedicalInfoController.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maid updated successfully')),
      );
    } catch (e) {
      debugPrint('Error updating maid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating maid: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _tribeController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinContactController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _otherMedicalInfoController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
