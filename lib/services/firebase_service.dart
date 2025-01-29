import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth Methods
  static Future<UserCredential?> signInWithPhoneAndPassword(
    String phone,
    String password,
  ) async {
    try {
      // First check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (userDoc.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this phone number.',
        );
      }

      // Get email from Firestore (we use email+password auth behind the scenes)
      final email = userDoc.docs.first.data()['email'] as String;

      // Sign in with email and password
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // User Methods
  static Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() ?? {};
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> getUserType(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData['type'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  static Stream<DocumentSnapshot> userDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Maid Methods
  static Future<void> submitMaidRegistration(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload profile photo if provided
      if (data['profilePhoto'] != null) {
        final photoRef = _storage.ref().child('profile_photos/${user.uid}');
        await photoRef.putFile(data['profilePhoto']);
        data['profilePhotoUrl'] = await photoRef.getDownloadURL();
      }

      // Upload documents
      if (data['documents'] != null) {
        final Map<String, String> documentUrls = {};
        for (var entry in (data['documents'] as Map).entries) {
          final docRef = _storage
              .ref()
              .child('documents/${user.uid}/${entry.key}');
          await docRef.putFile(entry.value);
          documentUrls[entry.key] = await docRef.getDownloadURL();
        }
        data['documentUrls'] = documentUrls;
      }

      // Save to Firestore
      await _firestore.collection('maid_applications').doc(user.uid).set({
        ...data,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Admin Methods
  static Future<List<Map<String, dynamic>>> getPendingApplications() async {
    try {
      final snapshot = await _firestore
          .collection('maid_applications')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
    String? comment,
  ) async {
    try {
      await _firestore.collection('maid_applications').doc(applicationId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.uid,
        if (comment != null) 'reviewComment': comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Homeowner Methods
  static Future<List<Map<String, dynamic>>> searchMaids(
    Map<String, dynamic> filters,
  ) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('type', isEqualTo: 'maid')
          .where('status', isEqualTo: 'active');

      if (filters['location'] != null) {
        query = query.where('location', isEqualTo: filters['location']);
      }

      if (filters['skills'] != null) {
        query = query.where('skills', arrayContainsAny: filters['skills']);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Messaging Methods
  static Future<void> sendMessage(
    String recipientId,
    String message,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = [user.uid, recipientId]..sort().join('_');

      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': user.uid,
        'recipientId': recipientId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [user.uid, recipientId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getChatMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final chatId = [user.uid, otherUserId]..sort().join('_');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Notification Methods
  static Future<void> sendNotification(
    String userId,
    String title,
    String body,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
