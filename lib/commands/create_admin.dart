import 'package:firebase_core/firebase_core.dart';
import 'package:maidmatch/services/auth_service.dart';
import 'package:maidmatch/config/firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with the correct options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Create admin account
    await AuthService.createAdminAccount(
      phone: '0700000001', // Change this to your preferred admin phone number
      firstName: 'Admin',
      lastName: 'User',
    );

    print('Admin account created successfully. You can now login with the phone number 0700000001');
  } catch (e) {
    print('Error creating admin account: $e');
  }
}
