import 'package:firebase_core/firebase_core.dart';
import 'firebase_config.dart';

class FirebaseInit {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        appId: FirebaseConfig.appId,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
        authDomain: FirebaseConfig.authDomain,
        measurementId: FirebaseConfig.measurementId,
      ),
    );
  }
}
