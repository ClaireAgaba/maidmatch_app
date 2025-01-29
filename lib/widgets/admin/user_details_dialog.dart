import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maidmatch/screens/admin/edit_maid_screen.dart';

class UserDetailsDialog extends StatelessWidget {
  final String userId;

  const UserDetailsDialog({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final medicalHistory = userData['medicalHistory'] as Map<String, dynamic>? ?? {};
          final nextOfKin = userData['nextOfKin'] as Map<String, dynamic>? ?? {};
          final location = userData['location'] as Map<String, dynamic>? ?? {};

          return Container(
            width: 800,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(userData['userType'] ?? 'Maid'),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMaidScreen(maidId: userId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(userData['status'] ?? 'Pending'),
                      backgroundColor: Colors.orange[100],
                      labelStyle: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Contact Information',
                            items: [
                              _InfoItem(
                                label: 'Phone',
                                value: userData['phone']?.toString() ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Location',
                                value: location['address'] ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Nationality',
                                value: userData['nationality'] ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Tribe',
                                value: userData['tribe'] ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Marital Status',
                                value: userData['maritalStatus'] ?? 'Not provided',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Next of Kin',
                            items: [
                              _InfoItem(
                                label: 'Name',
                                value: nextOfKin['name'] ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Contact',
                                value: nextOfKin['contact']?.toString() ?? 'Not provided',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills & Experience',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Education & Languages',
                            items: [
                              _InfoItem(
                                label: 'Education',
                                value: userData['educationLevel'] ?? 'Not provided',
                              ),
                              _InfoItem(
                                label: 'Languages',
                                value: (userData['languages'] as List<dynamic>?)
                                        ?.join(', ') ??
                                    'Not provided',
                              ),
                              _InfoItem(
                                label: 'Services',
                                value: (userData['services'] as List<dynamic>?)
                                        ?.join(', ') ??
                                    'Not provided',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Medical Information',
                            items: [
                              if (medicalHistory['hasAllergies'] == true)
                                _InfoItem(
                                  label: 'Allergies',
                                  value: medicalHistory['allergies'] ?? 'Not specified',
                                ),
                              if (medicalHistory['hasChronicDiseases'] == true)
                                _InfoItem(
                                  label: 'Chronic Diseases',
                                  value: medicalHistory['chronicDiseases'] ??
                                      'Not specified',
                                ),
                              if (medicalHistory['otherInfo']?.isNotEmpty ?? false)
                                _InfoItem(
                                  label: 'Other Info',
                                  value: medicalHistory['otherInfo'],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DocumentCard(
                        title: 'National ID',
                        isUploaded: userData['documents']?['nationalId'] != null,
                        onView: () {
                          // TODO: Implement document view
                        },
                      ),
                      _DocumentCard(
                        title: 'Medical Certificate',
                        isUploaded: userData['documents']?['medicalCertificate'] != null,
                        onView: () {
                          // TODO: Implement document view
                        },
                      ),
                      _DocumentCard(
                        title: 'Police Clearance',
                        isUploaded: userData['documents']?['policeClearance'] != null,
                        onView: () {
                          // TODO: Implement document view
                        },
                      ),
                      _DocumentCard(
                        title: 'Reference Letter',
                        isUploaded: userData['documents']?['referenceLetter'] != null,
                        onView: () {
                          // TODO: Implement document view
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final VoidCallback onView;

  const _DocumentCard({
    required this.title,
    required this.isUploaded,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.description : Icons.upload_file,
              size: 32,
              color: isUploaded ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            if (isUploaded)
              TextButton(
                onPressed: onView,
                child: const Text('View'),
              ),
          ],
        ),
      ),
    );
  }
}
