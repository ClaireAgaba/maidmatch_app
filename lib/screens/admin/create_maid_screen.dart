import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class CreateMaidScreen extends StatefulWidget {
  const CreateMaidScreen({super.key});

  @override
  State<CreateMaidScreen> createState() => _CreateMaidScreenState();
}

class _CreateMaidScreenState extends State<CreateMaidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

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

  // Documents
  File? _nationalIdFile;
  File? _medicalCertificateFile;
  File? _policeClearanceFile;
  File? _lcLetterFile;
  File? _educationCertificateFile;

  // Loading state
  bool _isLoading = false;

  // Lists for dropdowns
  final List<String> _genderOptions = ['Female', 'Male'];
  final List<String> _nationalityOptions = [
    'Uganda',
    'Kenya',
    'Tanzania',
    'Rwanda',
    'Burundi',
    'South Sudan',
  ];
  final List<String> _maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _educationLevelOptions = [
    'Primary',
    'O-Level',
    'A-Level',
    'Certificate',
    'Diploma',
    'Degree'
  ];
  final List<String> _languageOptions = [
    'English',
    'Luganda',
    'Swahili',
    'Runyankole',
    'Lusoga',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Please enable it in settings.'),
          ),
        );
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = latLng;
      });

      // Move map camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 15,
            ),
          ),
        );
      }

      // Get address from coordinates
      await _getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      debugPrint('Getting address for: ${position.latitude}, ${position.longitude}');
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        debugPrint('Placemark data: $place');
        debugPrint('Name: ${place.name}');
        debugPrint('Street: ${place.street}');
        debugPrint('Thoroughfare: ${place.thoroughfare}');
        debugPrint('Sublocality: ${place.subLocality}');
        debugPrint('Locality: ${place.locality}');
        debugPrint('Area: ${place.administrativeArea}');
        
        // Build address with most specific information first
        final addressParts = <String>[];
        
        // Add specific location name if available
        if (place.name != null && place.name != place.street) {
          addressParts.add(place.name!);
        }
        
        // Add street or thoroughfare
        if (place.thoroughfare?.isNotEmpty ?? false) {
          addressParts.add(place.thoroughfare!);
        } else if (place.street?.isNotEmpty ?? false) {
          addressParts.add(place.street!);
        }
        
        // Add area information
        if (place.subLocality?.isNotEmpty ?? false) {
          addressParts.add(place.subLocality!);
        }
        
        // Add city/town
        if (place.locality?.isNotEmpty ?? false) {
          addressParts.add(place.locality!);
        }
        
        // Remove duplicates while preserving order
        final uniqueAddressParts = addressParts.toSet().toList();
        
        setState(() {
          _selectedAddress = uniqueAddressParts.join(', ');
          if (_selectedAddress.isEmpty) {
            _selectedAddress = 'Location selected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          }
        });
        
        debugPrint('Final formatted address: $_selectedAddress');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Location selected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      });
    }
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _selectedLocation!,
                            zoom: 15,
                          ),
                        ),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(0.3476, 32.5825), // Default to Kampala
                    zoom: 15,
                  ),
                  markers: _selectedLocation != null ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedLocation = newPosition;
                        });
                        _getAddressFromLatLng(newPosition);
                      },
                    ),
                  } : {},
                  onTap: (position) {
                    setState(() {
                      _selectedLocation = position;
                    });
                    _getAddressFromLatLng(position);
                    debugPrint('Map tapped at: ${position.latitude}, ${position.longitude}');
                  },
                ),
              ),
              const SizedBox(height: 16),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedLocation != null) {
                Navigator.pop(context);
                // Update the form field or display
                setState(() {});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a location')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadServices() async {
    try {
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();
      
      setState(() {
        _selectedServices.clear();
        for (var doc in servicesSnapshot.docs) {
          final serviceData = doc.data();
          if (serviceData['name'] != null) {
            _selectedServices.add(serviceData['name'] as String);
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          switch (type) {
            case 'nationalId':
              _nationalIdFile = file;
              break;
            case 'medicalCertificate':
              _medicalCertificateFile = file;
              break;
            case 'policeClearance':
              _policeClearanceFile = file;
              break;
            case 'lcLetter':
              _lcLetterFile = file;
              break;
            case 'educationCertificate':
              _educationCertificateFile = file;
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _createMaid() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nationalIdFile == null ||
        _policeClearanceFile == null ||
        _lcLetterFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload documents
      final nationalIdUrl = await _uploadFile(
        _nationalIdFile!,
        'maids/documents/${DateTime.now().millisecondsSinceEpoch}_national_id'
      );
      final policeClearanceUrl = await _uploadFile(
        _policeClearanceFile!,
        'maids/documents/${DateTime.now().millisecondsSinceEpoch}_police_clearance'
      );
      final lcLetterUrl = await _uploadFile(
        _lcLetterFile!,
        'maids/documents/${DateTime.now().millisecondsSinceEpoch}_lc_letter'
      );

      String? medicalCertificateUrl;
      if (_medicalCertificateFile != null) {
        medicalCertificateUrl = await _uploadFile(
          _medicalCertificateFile!,
          'maids/documents/${DateTime.now().millisecondsSinceEpoch}_medical_certificate'
        );
      }

      String? educationCertificateUrl;
      if (_educationCertificateFile != null) {
        educationCertificateUrl = await _uploadFile(
          _educationCertificateFile!,
          'maids/documents/${DateTime.now().millisecondsSinceEpoch}_education_certificate'
        );
      }

      // Create maid document
      await FirebaseFirestore.instance.collection('users').add({
        'type': 'maid',
        'status': 'pending',
        // Bio Data
        'firstName': _surnameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'gender': _gender,
        // Personal Info
        'phone': int.parse(_phoneController.text.trim()),
        'nationality': _nationality,
        'tribe': _tribeController.text.trim(),
        'maritalStatus': _maritalStatus,
        'nextOfKin': {
          'name': _nextOfKinNameController.text.trim(),
          'contact': int.parse(_nextOfKinContactController.text.trim()),
        },
        // Location
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address': _selectedAddress,
        },
        // Skills
        'educationLevel': _educationLevel,
        'languages': _selectedLanguages,
        'services': _selectedServices,
        // Medical History
        'medicalHistory': {
          'hasAllergies': _hasAllergies,
          'allergies': _hasAllergies ? _allergiesController.text.trim() : null,
          'hasChronicDiseases': _hasChronicDiseases,
          'chronicDiseases': _hasChronicDiseases ? _chronicDiseasesController.text.trim() : null,
          'otherInfo': _otherMedicalInfoController.text.trim(),
        },
        // Documents
        'documents': {
          'nationalId': nationalIdUrl,
          'policeClearance': policeClearanceUrl,
          'lcLetter': lcLetterUrl,
          'medicalCertificate': medicalCertificateUrl,
          'educationCertificate': educationCertificateUrl,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maid created successfully')),
      );
    } catch (e) {
      debugPrint('Error creating maid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating maid: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Maid Account'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            setState(() {
              if (_currentStep < 4) {
                _currentStep++;
              } else {
                _createMaid();
              }
            });
          },
          onStepCancel: () {
            setState(() {
              if (_currentStep > 0) {
                _currentStep--;
              }
            });
          },
          steps: [
            // Bio Data Step
            Step(
              title: const Text('Bio Data'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Surname *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter surname' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter last name' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date of Birth *'),
                    subtitle: Text(_dateOfBirth == null
                        ? 'Select date'
                        : DateFormat('dd/MM/yyyy').format(_dateOfBirth!)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                      );
                      if (date != null) {
                        setState(() => _dateOfBirth = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender *'),
                    items: _genderOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _gender = value);
                      }
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            // Personal Info Step
            Step(
              title: const Text('Personal Info'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number *'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter phone number';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value!)) {
                        return 'Please enter only numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Location *'),
                    subtitle: Text(_selectedAddress.isEmpty ? 'Select location' : _selectedAddress),
                    trailing: const Icon(Icons.map),
                    onTap: _showLocationPicker,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _nationality,
                    decoration: const InputDecoration(labelText: 'Nationality *'),
                    items: _nationalityOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _nationality = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tribeController,
                    decoration: const InputDecoration(labelText: 'Tribe *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter tribe' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration: const InputDecoration(labelText: 'Marital Status *'),
                    items: _maritalStatusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _maritalStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nextOfKinNameController,
                    decoration: const InputDecoration(labelText: 'Next of Kin Name *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter next of kin name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nextOfKinContactController,
                    decoration: const InputDecoration(labelText: 'Next of Kin Contact *'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter next of kin contact';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value!)) {
                        return 'Please enter only numbers';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            // Skills Step
            Step(
              title: const Text('Skills'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _educationLevel,
                    decoration: const InputDecoration(labelText: 'Education Level *'),
                    items: _educationLevelOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _educationLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Languages *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _languageOptions.map((language) {
                      return FilterChip(
                        label: Text(language),
                        selected: _selectedLanguages.contains(language),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedLanguages.add(language);
                            } else {
                              _selectedLanguages.remove(language);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Services *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('services')
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      return Wrap(
                        spacing: 8,
                        children: snapshot.data!.docs.map((doc) {
                          final service = doc.data() as Map<String, dynamic>;
                          final serviceName = service['name'] as String;
                          return FilterChip(
                            label: Text(serviceName),
                            selected: _selectedServices.contains(serviceName),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(serviceName);
                                } else {
                                  _selectedServices.remove(serviceName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
            // Medical History Step
            Step(
              title: const Text('Medical History'),
              content: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Has Allergies?'),
                    value: _hasAllergies,
                    onChanged: (bool value) {
                      setState(() => _hasAllergies = value);
                    },
                  ),
                  if (_hasAllergies) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies',
                        hintText: 'Describe the allergies',
                      ),
                      maxLines: 2,
                      validator: (value) => _hasAllergies && (value?.isEmpty ?? true)
                          ? 'Please describe the allergies'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Has Chronic Diseases?'),
                    value: _hasChronicDiseases,
                    onChanged: (bool value) {
                      setState(() => _hasChronicDiseases = value);
                    },
                  ),
                  if (_hasChronicDiseases) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _chronicDiseasesController,
                      decoration: const InputDecoration(
                        labelText: 'Chronic Diseases',
                        hintText: 'Describe the chronic diseases',
                      ),
                      maxLines: 2,
                      validator: (value) => _hasChronicDiseases && (value?.isEmpty ?? true)
                          ? 'Please describe the chronic diseases'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otherMedicalInfoController,
                    decoration: const InputDecoration(
                      labelText: 'Other Medical Information',
                      hintText: 'Enter any other medical information',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
            // Documents Step
            Step(
              title: const Text('Documents'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocumentUpload(
                    'National ID *',
                    _nationalIdFile,
                    () => _pickFile('nationalId'),
                  ),
                  _buildDocumentUpload(
                    'Medical Certificate (for permanent)',
                    _medicalCertificateFile,
                    () => _pickFile('medicalCertificate'),
                  ),
                  _buildDocumentUpload(
                    'Police Clearance *',
                    _policeClearanceFile,
                    () => _pickFile('policeClearance'),
                  ),
                  _buildDocumentUpload(
                    'LC Letter *',
                    _lcLetterFile,
                    () => _pickFile('lcLetter'),
                  ),
                  _buildDocumentUpload(
                    'Education Certificate (for permanent)',
                    _educationCertificateFile,
                    () => _pickFile('educationCertificate'),
                  ),
                ],
              ),
              isActive: _currentStep >= 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String label, File? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    file == null ? Icons.upload_file : Icons.check_circle,
                    color: file == null ? Colors.grey : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file?.path.split('/').last ?? 'Select file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    _surnameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _tribeController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinContactController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _otherMedicalInfoController.dispose();
    super.dispose();
  }
}
