import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:maidmatch/config/firebase_options.dart';
import 'package:maidmatch/services/auth_service.dart';

class CreateAdminUtil {
  static Future<void> createAdmin() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      await AuthService.createAdminAccount(
        phone: '0700000001',
        firstName: 'Admin',
        lastName: 'User',
      );
      debugPrint('Admin account created successfully!');
    } catch (e) {
      debugPrint('Error creating admin: $e');
      rethrow;
    }
  }
}
