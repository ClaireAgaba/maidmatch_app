import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const bool _isTestMode = true; // Set to false for production
  
  /// Initialize reCAPTCHA for web
  static Future<void> initWebRecaptcha() async {
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
      debugPrint('Initialized auth for web');
    }
  }

  /// Format phone number to E.164 format
  static String _formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove leading 0 if present
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    
    // Add country code if not present
    if (!phone.startsWith('256')) {
      phone = '256$phone';
    }
    
    return '+$phone';
  }

  /// Start the OTP login process
  static Future<void> sendOTP(String phone) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');

      debugPrint('Sending OTP to: $formattedPhone');

      // Check if user exists
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: rawPhone)
          .get();

      // If user doesn't exist, create one
      if (userQuery.docs.isEmpty) {
        final userRef = _firestore.collection('users').doc();
        await userRef.set({
          'userId': userRef.id,
          'phone': rawPhone,
          'type': 'user',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Created new user account for: $rawPhone');
      }

      if (_isTestMode) {
        // In test mode, just store the phone number
        await _firestore.collection('otp_sessions').doc(formattedPhone).set({
          'phone': rawPhone,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Test mode: OTP sent successfully');
        return;
      }

      // Send OTP using Firebase Auth
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          throw Exception(e.message ?? 'Failed to send OTP');
        },
        codeSent: (String verificationId, int? resendToken) async {
          debugPrint('OTP sent successfully');
          await _firestore.collection('otp_sessions').doc(formattedPhone).set({
            'verificationId': verificationId,
            'createdAt': FieldValue.serverTimestamp(),
            'phone': rawPhone,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('OTP auto-retrieval timeout');
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      rethrow;
    }
  }

  /// Verify the OTP entered by the user
  static Future<void> verifyOTP(String phone, String otp) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');
      debugPrint('Verifying OTP for: $formattedPhone');

      if (_isTestMode) {
        if (otp != '123456') {
          throw Exception('Invalid OTP');
        }

        // Check for existing applications to determine user type
        String userType = 'user';
        
        // Check for admin
        final adminQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: rawPhone)
            .where('type', isEqualTo: 'admin')
            .get();
        
        if (adminQuery.docs.isNotEmpty) {
          userType = 'admin';
        } else {
          // Check for approved maid application
          final maidQuery = await _firestore
              .collection('maid_applications')
              .where('phone', isEqualTo: rawPhone)
              .where('status', isEqualTo: 'approved')
              .get();
          
          if (maidQuery.docs.isNotEmpty) {
            userType = 'maid';
          } else {
            // Check for approved homeowner application
            final homeownerQuery = await _firestore
                .collection('homeowner_applications')
                .where('phone', isEqualTo: rawPhone)
                .where('status', isEqualTo: 'approved')
                .get();
            
            if (homeownerQuery.docs.isNotEmpty) {
              userType = 'homeowner';
            }
          }
        }

        // In test mode, sign in with a test email/password
        final testEmail = 'test@example.com';
        final testPassword = 'Test123!';

        try {
          // Try to sign in with test account
          await _auth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
        } catch (e) {
          // If test account doesn't exist, create it
          await _auth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
        }

        // Update the user's phone number and type in Firestore
        final user = _auth.currentUser;
        if (user != null) {
          final userDoc = _firestore.collection('users').doc(user.uid);
          await userDoc.set({
            'userId': user.uid,
            'phone': rawPhone,
            'email': testEmail,
            'type': userType,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        debugPrint('Test mode: Signed in successfully as $userType');
        return;
      }

      // Get the verification ID from Firestore
      final doc = await _firestore.collection('otp_sessions').doc(formattedPhone).get();
      if (!doc.exists) {
        throw Exception('No OTP session found. Please request a new OTP.');
      }

      final verificationId = doc.get('verificationId') as String;

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      await _auth.signInWithCredential(credential);
      debugPrint('OTP verified successfully');

      // Clean up OTP session
      await _firestore.collection('otp_sessions').doc(formattedPhone).delete();
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Get the type of the currently logged-in user
  static Future<String> getUserType() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Getting user type for: ${user.uid}');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final userType = doc.get('type') as String;
      debugPrint('User type: $userType');
      return userType;
    } catch (e) {
      debugPrint('Error getting user type: $e');
      rethrow;
    }
  }

  /// Create admin account if it doesn't exist
  static Future<void> createAdminAccount({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');

      // Check if admin already exists
      final existingUser = await _firestore
          .collection('users')
          .where('phone', isEqualTo: rawPhone)
          .where('type', isEqualTo: 'admin')
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint('Admin already exists with this phone number');
        return; // Return silently if admin exists
      }

      // Create admin user document
      final userRef = _firestore.collection('users').doc();
      await userRef.set({
        'userId': userRef.id,
        'phone': rawPhone,
        'firstName': firstName,
        'lastName': lastName,
        'type': 'admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Admin account created successfully');
    } catch (e) {
      debugPrint('Error creating admin account: $e');
      rethrow;
    }
  }

  /// Submit maid application
  static Future<void> submitMaidApplication({
    required String phone,
    required String firstName,
    required String lastName,
    required String location,
    required List<String> skills,
    String? photoUrl,
    String? nationalIdUrl,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? nextOfKinRelation,
  }) async {
    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');

      // Create application document
      final applicationRef = _firestore.collection('maid_applications').doc();
      await applicationRef.set({
        'applicationId': applicationRef.id,
        'phone': rawPhone,
        'firstName': firstName,
        'lastName': lastName,
        'location': location,
        'skills': skills,
        'photoUrl': photoUrl,
        'nationalIdUrl': nationalIdUrl,
        'nextOfKinName': nextOfKinName,
        'nextOfKinPhone': nextOfKinPhone,
        'nextOfKinRelation': nextOfKinRelation,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Maid application submitted successfully');
    } catch (e) {
      debugPrint('Error submitting maid application: $e');
      rethrow;
    }
  }

  /// Submit homeowner application
  static Future<void> submitHomeownerApplication({
    required String phone,
    required String firstName,
    required String lastName,
    required String location,
  }) async {
    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');

      // Create application document
      final applicationRef = _firestore.collection('homeowner_applications').doc();
      await applicationRef.set({
        'applicationId': applicationRef.id,
        'phone': rawPhone,
        'firstName': firstName,
        'lastName': lastName,
        'location': location,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Homeowner application submitted successfully');
    } catch (e) {
      debugPrint('Error submitting homeowner application: $e');
      rethrow;
    }
  }

  /// Update application status (for both maid and homeowner)
  static Future<void> updateApplicationStatus({
    required String applicationId,
    required String applicationType,
    required String status,
    String? comment,
  }) async {
    try {
      final collection = applicationType == 'maid' 
          ? 'maid_applications' 
          : 'homeowner_applications';
          
      await _firestore.collection(collection).doc(applicationId).update({
        'status': status,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'approved') {
        // Get application data
        final doc = await _firestore.collection(collection).doc(applicationId).get();
        if (!doc.exists) throw Exception('Application not found');
        
        final data = doc.data()!;
        
        // Create user account
        await _firestore.collection('users').doc().set({
          'phone': data['phone'],
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'location': data['location'],
          'type': applicationType,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Application status updated successfully');
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }

  /// Update maid application status
  static Future<void> updateMaidApplicationStatus(
    String applicationId,
    String status,
    String? comment,
  ) async {
    try {
      await _firestore.collection('maid_applications').doc(applicationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (comment != null) 'comment': comment,
      });
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }

  /// Get pending maid applications
  static Stream<QuerySnapshot> getPendingMaidApplications() {
    return _firestore
        .collection('maid_applications')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get current user data
  static Future<DocumentSnapshot> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final rawPhone = user.phoneNumber?.replaceAll('+256', '');
      final doc = await _firestore
          .collection('users')
          .where('phone', isEqualTo: rawPhone)
          .get();

      if (doc.docs.isEmpty) {
        throw Exception('User document not found');
      }

      return doc.docs.first;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Sign up a new maid with all their details
  static Future<void> signUpMaid({
    required String phone,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
    required String nationality,
    required String tribe,
    required String maritalStatus,
    required Map<String, dynamic> location,
    required String educationLevel,
    required List<String> languages,
    required List<String> services,
    required Map<String, dynamic> medicalHistory,
    required Map<String, dynamic> documents,
    required Map<String, dynamic> nextOfKin,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final rawPhone = formattedPhone.replaceAll('+256', '');

      // Create user document
      await _firestore.collection('users').doc(rawPhone).set({
        'phone': rawPhone,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'nationality': nationality,
        'tribe': tribe,
        'maritalStatus': maritalStatus,
        'location': location,
        'educationLevel': educationLevel,
        'languages': languages,
        'services': services,
        'medicalHistory': medicalHistory,
        'documents': documents,
        'nextOfKin': nextOfKin,
        'userType': 'maid',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Maid registered successfully: $rawPhone');
    } catch (e) {
      debugPrint('Error registering maid: $e');
      rethrow;
    }
  }
}
