import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:maidmatch/services/auth_service.dart';
import 'package:maidmatch/services/storage_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MaidRegistrationScreen extends StatefulWidget {
  const MaidRegistrationScreen({super.key});

  @override
  State<MaidRegistrationScreen> createState() => _MaidRegistrationScreenState();
}

class _MaidRegistrationScreenState extends State<MaidRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Bio Data
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Female';

  // Personal Info
  final _phoneController = TextEditingController();
  String _nationality = 'Uganda';
  final _tribeController = TextEditingController();
  String _maritalStatus = 'Single';
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();

  // Location
  final _addressController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  List<String> _addressSuggestions = [];
  bool _isSearching = false;
  GoogleMapController? _mapController;
  bool _showMap = true;

  void _searchAddress(String query) {
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _addressSuggestions = _ugandaLocations.keys
          .where((location) =>
              location.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _isSearching = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newLocation);
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(newLocation),
        );
      }

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = <String>[];
          
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(place.subAdministrativeArea!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }

          final address = addressParts.join(', ');
          setState(() {
            _selectedAddress = address;
            _addressController.text = address;
          });
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting location')),
      );
    }
  }

  // Predefined Uganda locations with coordinates
  final Map<String, LatLng> _ugandaLocations = {
    'Kampala Central, Kampala': LatLng(0.3476, 32.5825),
    'Nakawa, Kampala': LatLng(0.3349, 32.6217),
    'Kawempe, Kampala': LatLng(0.3847, 32.5544),
    'Makindye, Kampala': LatLng(0.3006, 32.6039),
    'Rubaga, Kampala': LatLng(0.3087, 32.5526),
    'Entebbe, Wakiso': LatLng(0.0611, 32.4649),
    'Wakiso Town': LatLng(0.4040, 32.4594),
    'Mukono Town': LatLng(0.3533, 32.7553),
    'Jinja City': LatLng(0.4250, 33.2039),
    'Masaka City': LatLng(-0.3333, 31.7333),
    'Gulu City': LatLng(2.7747, 32.2990),
    'Lira City': LatLng(2.2499, 32.8999),
    'Mbarara City': LatLng(-0.6167, 30.6583),
    'Arua City': LatLng(3.0200, 30.9100),
    'Mbale City': LatLng(1.0819, 34.1753),
    'Fort Portal City': LatLng(0.6710, 30.2752),
    'Hoima City': LatLng(1.4333, 31.3500),
    'Soroti City': LatLng(1.7147, 33.6112),
    'Moroto Municipality': LatLng(2.5344, 34.6667),
    'Tororo Municipality': LatLng(0.6925, 34.1809),
  };

  // Skills & Education
  String _educationLevel = 'Primary';
  final List<String> _selectedLanguages = [];
  final List<String> _selectedServices = [];

  final List<String> _availableLanguages = [
    'English',
    'Swahili',
    'Luganda',
    'Runyankole',
  ];

  final List<String> _availableServices = [
    'Cleaning',
    'Cooking',
    'Laundry',
    'Child Care',
    'Elder Care',
    'Pet Care',
    'Gardening',
  ];

  // Medical History
  bool _hasAllergies = false;
  bool _hasChronicDiseases = false;
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _otherMedicalInfoController = TextEditingController();

  // Documents
  XFile? _profilePhotoWeb;
  XFile? _nationalIdPhotoWeb;
  XFile? _medicalReportWeb;
  XFile? _policeClearanceWeb;
  XFile? _lcLetterWeb;
  XFile? _educationCertificateWeb;
  
  File? _profilePhoto;
  File? _nationalIdPhoto;
  File? _medicalReport;
  File? _policeClearance;
  File? _lcLetter;
  File? _educationCertificate;
  
  String? _profilePhotoUrl;
  String? _nationalIdPhotoUrl;
  String? _medicalReportUrl;
  String? _policeClearanceUrl;
  String? _lcLetterUrl;
  String? _educationCertificateUrl;

  bool _isLoading = false;
  bool _showPreview = false;

  Future<void> _pickImage({
    ImageSource source = ImageSource.gallery,
    bool isProfile = false,
    bool isMedicalReport = false,
    bool isPoliceClearance = false,
    bool isLCLetter = false,
    bool isEducationCertificate = false,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        if (kIsWeb) {
          if (isProfile) {
            _profilePhotoWeb = pickedFile;
            _profilePhoto = null;
          } else if (isMedicalReport) {
            _medicalReportWeb = pickedFile;
            _medicalReport = null;
          } else if (isPoliceClearance) {
            _policeClearanceWeb = pickedFile;
            _policeClearance = null;
          } else if (isLCLetter) {
            _lcLetterWeb = pickedFile;
            _lcLetter = null;
          } else if (isEducationCertificate) {
            _educationCertificateWeb = pickedFile;
            _educationCertificate = null;
          } else {
            _nationalIdPhotoWeb = pickedFile;
            _nationalIdPhoto = null;
          }
        } else {
          if (isProfile) {
            _profilePhoto = File(pickedFile.path);
            _profilePhotoWeb = null;
          } else if (isMedicalReport) {
            _medicalReport = File(pickedFile.path);
            _medicalReportWeb = null;
          } else if (isPoliceClearance) {
            _policeClearance = File(pickedFile.path);
            _policeClearanceWeb = null;
          } else if (isLCLetter) {
            _lcLetter = File(pickedFile.path);
            _lcLetterWeb = null;
          } else if (isEducationCertificate) {
            _educationCertificate = File(pickedFile.path);
            _educationCertificateWeb = null;
          } else {
            _nationalIdPhoto = File(pickedFile.path);
            _nationalIdPhotoWeb = null;
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImagePicker(String label, bool isProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take a photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(source: ImageSource.camera, isProfile: isProfile);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Choose from gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(source: ImageSource.gallery, isProfile: isProfile);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _getImagePreview(isProfile),
          ),
        ),
      ],
    );
  }

  Widget _getImagePreview(bool isProfile) {
    if (isProfile) {
      if (_profilePhotoWeb != null || _profilePhoto != null) {
        return kIsWeb
            ? Image.network(_profilePhotoWeb!.path, fit: BoxFit.cover)
            : Image.file(_profilePhoto!, fit: BoxFit.cover);
      }
    } else {
      if (_nationalIdPhotoWeb != null || _nationalIdPhoto != null) {
        return kIsWeb
            ? Image.network(_nationalIdPhotoWeb!.path, fit: BoxFit.cover)
            : Image.file(_nationalIdPhoto!, fit: BoxFit.cover);
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 40),
          const SizedBox(height: 8),
          Text('Upload ${isProfile ? 'Profile Photo' : 'National ID'}'),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog(bool isProfile) async {
    if (kIsWeb) {
      // Web only supports gallery
      await _pickImage(source: ImageSource.gallery, isProfile: isProfile);
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(source: ImageSource.camera, isProfile: isProfile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(source: ImageSource.gallery, isProfile: isProfile);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Search Location',
            hintText: 'Search or select on map below',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            if (value.length > 2) {
              _searchAddress(value);
            } else {
              setState(() {
                _addressSuggestions = [];
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty || _selectedLocation == null) {
              return 'Please select a location';
            }
            return null;
          },
        ),
        if (_addressSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _addressSuggestions.length,
              itemBuilder: (context, index) {
                final address = _addressSuggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(address),
                  onTap: () {
                    _addressController.text = address;
                    final location = _ugandaLocations[address]!;
                    setState(() {
                      _selectedAddress = address;
                      _selectedLocation = location;
                      _addressSuggestions = [];
                      _showMap = false;
                    });
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(location),
                    );
                  },
                );
              },
            ),
          ),
        ],
        if (_selectedAddress.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAddress,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_location_alt),
                  onPressed: () {
                    setState(() {
                      _showMap = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedAddress = '';
                      _selectedLocation = null;
                      _addressController.clear();
                      _showMap = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        if (_showMap && (_selectedAddress.isEmpty || _addressSuggestions.isEmpty)) ...[
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
                        target: _selectedLocation ?? const LatLng(0.3476, 32.5825), // Kampala
                        zoom: 12,
                      ),
                      markers: _selectedLocation != null ? {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: _selectedLocation!,
                          draggable: true,
                          onDragEnd: (newPosition) async {
                            setState(() => _selectedLocation = newPosition);
                            // Get address for the new position
                            try {
                              final placemarks = await placemarkFromCoordinates(
                                newPosition.latitude,
                                newPosition.longitude,
                              );

                              if (placemarks.isNotEmpty) {
                                final place = placemarks.first;
                                final addressParts = <String>[];
                                
                                if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                                  addressParts.add(place.subLocality!);
                                }
                                if (place.locality != null && place.locality!.isNotEmpty) {
                                  addressParts.add(place.locality!);
                                }
                                if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
                                  addressParts.add(place.subAdministrativeArea!);
                                }
                                if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                                  addressParts.add(place.administrativeArea!);
                                }

                                final address = addressParts.join(', ');
                                setState(() {
                                  _selectedAddress = address;
                                  _addressController.text = address;
                                  _showMap = false;
                                });
                              }
                            } catch (e) {
                              debugPrint('Error getting address: $e');
                            }
                          },
                        ),
                      } : {},
                      onTap: (position) async {
                        setState(() => _selectedLocation = position);
                        // Get address for the tapped position
                        try {
                          final placemarks = await placemarkFromCoordinates(
                            position.latitude,
                            position.longitude,
                          );

                          if (placemarks.isNotEmpty) {
                            final place = placemarks.first;
                            final addressParts = <String>[];
                            
                            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                              addressParts.add(place.subLocality!);
                            }
                            if (place.locality != null && place.locality!.isNotEmpty) {
                              addressParts.add(place.locality!);
                            }
                            if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
                              addressParts.add(place.subAdministrativeArea!);
                            }
                            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                              addressParts.add(place.administrativeArea!);
                            }

                            final address = addressParts.join(', ');
                            setState(() {
                              _selectedAddress = address;
                              _addressController.text = address;
                              _showMap = false;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error getting address: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use Current Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload profile photo
      String? profilePhotoUrl;
      if (_profilePhotoWeb != null || _profilePhoto != null) {
        final bytes = kIsWeb
            ? await _profilePhotoWeb!.readAsBytes()
            : await _profilePhoto!.readAsBytes();
        profilePhotoUrl = await StorageService.uploadImage(
          'profile_photos',
          'profile_${_phoneController.text}',
          bytes,
        );
      }

      // Upload national ID
      String? nationalIdUrl;
      if (_nationalIdPhotoWeb != null || _nationalIdPhoto != null) {
        final bytes = kIsWeb
            ? await _nationalIdPhotoWeb!.readAsBytes()
            : await _nationalIdPhoto!.readAsBytes();
        nationalIdUrl = await StorageService.uploadImage(
          'national_ids',
          'national_id_${_phoneController.text}',
          bytes,
        );
      }

      // Upload medical report if provided
      String? medicalReportUrl;
      if (_medicalReportWeb != null || _medicalReport != null) {
        final bytes = kIsWeb
            ? await _medicalReportWeb!.readAsBytes()
            : await _medicalReport!.readAsBytes();
        medicalReportUrl = await StorageService.uploadImage(
          'medical_reports',
          'medical_report_${_phoneController.text}',
          bytes,
        );
      }

      // Upload police clearance if provided
      String? policeClearanceUrl;
      if (_policeClearanceWeb != null || _policeClearance != null) {
        final bytes = kIsWeb
            ? await _policeClearanceWeb!.readAsBytes()
            : await _policeClearance!.readAsBytes();
        policeClearanceUrl = await StorageService.uploadImage(
          'police_clearances',
          'police_clearance_${_phoneController.text}',
          bytes,
        );
      }

      // Upload LC letter if provided
      String? lcLetterUrl;
      if (_lcLetterWeb != null || _lcLetter != null) {
        final bytes = kIsWeb
            ? await _lcLetterWeb!.readAsBytes()
            : await _lcLetter!.readAsBytes();
        lcLetterUrl = await StorageService.uploadImage(
          'lc_letters',
          'lc_letter_${_phoneController.text}',
          bytes,
        );
      }

      // Upload education certificate if provided
      String? educationCertificateUrl;
      if (_educationCertificateWeb != null || _educationCertificate != null) {
        final bytes = kIsWeb
            ? await _educationCertificateWeb!.readAsBytes()
            : await _educationCertificate!.readAsBytes();
        educationCertificateUrl = await StorageService.uploadImage(
          'education_certificates',
          'education_certificate_${_phoneController.text}',
          bytes,
        );
      }

      // Register maid
      await AuthService.signUpMaid(
        phone: _phoneController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        gender: _gender,
        nationality: _nationality,
        tribe: _tribeController.text,
        maritalStatus: _maritalStatus,
        location: {
          'address': _selectedAddress,
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        educationLevel: _educationLevel,
        languages: _selectedLanguages,
        services: _selectedServices,
        medicalHistory: {
          'hasChronicIllness': _hasChronicDiseases,
          'chronicIllnessDetails': _chronicDiseasesController.text,
          'hasAllergies': _hasAllergies,
          'allergyDetails': _allergiesController.text,
          'medicalReportUrl': medicalReportUrl,
        },
        documents: {
          'profilePhotoUrl': profilePhotoUrl,
          'nationalIdUrl': nationalIdUrl,
          'policeClearanceUrl': policeClearanceUrl,
          'lcLetterUrl': lcLetterUrl,
          'educationCertificateUrl': educationCertificateUrl,
        },
        nextOfKin: {
          'name': _nextOfKinNameController.text,
          'phone': _nextOfKinPhoneController.text,
        },
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted successfully! We will review your application and contact you soon.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Add a slight delay to ensure the message is seen
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing up: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Preview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildPreviewItem('Profile Photo', _getImagePreview(true)),
          _buildPreviewItem('National ID', _getImagePreview(false)),
          _buildPreviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'),
          _buildPreviewItem('Phone', _phoneController.text),
          _buildPreviewItem('Location', _selectedAddress),
          _buildPreviewItem('Skills', _selectedServices.join(', ')),
          const Text(
            'Next of Kin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildPreviewItem('Name', _nextOfKinNameController.text),
          _buildPreviewItem('Phone', _nextOfKinPhoneController.text),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Application'),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() => _showPreview = false);
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (value is Widget) value else Text(value?.toString() ?? ''),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maid Registration'),
      ),
      body: _showPreview ? _buildPreview() : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bio Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
              const SizedBox(height: 24),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
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
                    return 'Please enter your phone number';
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
              const SizedBox(height: 24),
              const Text(
                'Next of Kin Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nextOfKinNameController,
                decoration: const InputDecoration(
                  labelText: 'Next of Kin Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter next of kin name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nextOfKinPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Next of Kin Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter next of kin phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              const Text(
                'Skills & Education',
                style: TextStyle(
                  fontSize: 18,
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
                children: _availableLanguages.map((lang) {
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
                children: _availableServices.map((service) {
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
              const SizedBox(height: 24),
              const Text(
                'Medical History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Do you have any allergies?'),
                value: _hasAllergies,
                onChanged: (value) {
                  setState(() => _hasAllergies = value);
                },
              ),
              if (_hasAllergies) ...[
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Please describe your allergies',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              SwitchListTile(
                title: const Text('Do you have any chronic diseases?'),
                value: _hasChronicDiseases,
                onChanged: (value) {
                  setState(() => _hasChronicDiseases = value);
                },
              ),
              if (_hasChronicDiseases) ...[
                TextFormField(
                  controller: _chronicDiseasesController,
                  decoration: const InputDecoration(
                    labelText: 'Please describe your chronic diseases',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _otherMedicalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Other Medical Information (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please upload clear images of the following documents:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker('Profile Photo', true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePicker('National ID', false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medical Report'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickImage(isMedicalReport: true),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _medicalReportWeb != null || _medicalReport != null
                                ? kIsWeb
                                    ? Image.network(
                                        _medicalReportWeb!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _medicalReport!,
                                        fit: BoxFit.cover,
                                      )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, size: 40),
                                        SizedBox(height: 8),
                                        Text('Upload Medical Report'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Police Clearance'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickImage(isPoliceClearance: true),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _policeClearanceWeb != null || _policeClearance != null
                                ? kIsWeb
                                    ? Image.network(
                                        _policeClearanceWeb!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _policeClearance!,
                                        fit: BoxFit.cover,
                                      )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, size: 40),
                                        SizedBox(height: 8),
                                        Text('Upload Police Clearance'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LC Letter'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickImage(isLCLetter: true),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _lcLetterWeb != null || _lcLetter != null
                                ? kIsWeb
                                    ? Image.network(
                                        _lcLetterWeb!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _lcLetter!,
                                        fit: BoxFit.cover,
                                      )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, size: 40),
                                        SizedBox(height: 8),
                                        Text('Upload LC Letter'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Education Certificate'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickImage(isEducationCertificate: true),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _educationCertificateWeb != null || _educationCertificate != null
                                ? kIsWeb
                                    ? Image.network(
                                        _educationCertificateWeb!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _educationCertificate!,
                                        fit: BoxFit.cover,
                                      )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, size: 40),
                                        SizedBox(height: 8),
                                        Text('Upload Education Certificate'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Preview Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    super.dispose();
  }
}
