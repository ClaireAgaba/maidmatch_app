import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get maids statistics
      final maidsSnapshot = await _firestore.collection('maid_applications').get();
      final approvedMaids = maidsSnapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
      final declinedMaids = maidsSnapshot.docs.where((doc) => doc.data()['status'] == 'rejected').length;
      final pendingMaids = maidsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final suspendedMaids = maidsSnapshot.docs.where((doc) => doc.data()['status'] == 'suspended').length;

      // Get homeowners statistics
      final homeownersSnapshot = await _firestore.collection('homeowner_applications').get();
      final approvedHomeowners = homeownersSnapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
      final declinedHomeowners = homeownersSnapshot.docs.where((doc) => doc.data()['status'] == 'rejected').length;
      final pendingHomeowners = homeownersSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final suspendedHomeowners = homeownersSnapshot.docs.where((doc) => doc.data()['status'] == 'suspended').length;

      // Get transactions statistics
      final transactionsSnapshot = await _firestore.collection('transactions').get();
      final totalRevenue = transactionsSnapshot.docs.fold(0.0, 
        (sum, doc) => sum + (doc.data()['commission'] as num? ?? 0).toDouble());
      final pendingTransactions = transactionsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final disputedTransactions = transactionsSnapshot.docs.where((doc) => doc.data()['status'] == 'disputed').length;

      // Get reports statistics
      final reportsSnapshot = await _firestore.collection('reports').get();
      final totalReports = reportsSnapshot.docs.length;
      final pendingReports = reportsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final resolvedReports = reportsSnapshot.docs.where((doc) => doc.data()['status'] == 'resolved').length;

      return {
        'users': {
          'total': approvedMaids + approvedHomeowners,
          'pending': pendingMaids + pendingHomeowners,
          'suspended': suspendedMaids + suspendedHomeowners,
        },
        'maids': {
          'approved': approvedMaids,
          'declined': declinedMaids,
          'pending': pendingMaids,
          'suspended': suspendedMaids,
        },
        'homeowners': {
          'approved': approvedHomeowners,
          'declined': declinedHomeowners,
          'pending': pendingHomeowners,
          'suspended': suspendedHomeowners,
        },
        'transactions': {
          'totalRevenue': totalRevenue,
          'pending': pendingTransactions,
          'disputed': disputedTransactions,
        },
        'reports': {
          'total': totalReports,
          'pending': pendingReports,
          'resolved': resolvedReports,
        }
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      rethrow;
    }
  }

  static Future<void> updateUserStatus(String collection, String docId, String newStatus) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }
}
