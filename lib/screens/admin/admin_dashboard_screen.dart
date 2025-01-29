import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maidmatch/services/auth_service.dart';
import 'package:maidmatch/services/statistics_service.dart';
import 'package:intl/intl.dart';
import 'create_maid_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _currentSection = 'dashboard';
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await StatisticsService.getDashboardStats();
      setState(() {
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard stats: $e')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  Widget _buildNavItem(String title, IconData icon, String section) {
    final isSelected = _currentSection == section;
    return ListTile(
      leading: Icon(icon, 
        color: isSelected ? Colors.deepPurple : Colors.grey[600],
      ),
      title: Text(title,
        style: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withOpacity(0.1),
      onTap: () {
        setState(() {
          _currentSection = section;
        });
        if (MediaQuery.of(context).size.width < 1200) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
            child: Icon(Icons.admin_panel_settings, 
              color: Colors.deepPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Welcome back, Admin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem('Dashboard', Icons.dashboard, 'dashboard'),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('MANAGEMENT',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildNavItem('Accounts', Icons.people, 'accounts'),
                _buildNavItem('Applications', Icons.app_registration, 'applications'),
                _buildNavItem('Services', Icons.cleaning_services, 'services'),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('SYSTEM',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildNavItem('Support', Icons.support_agent, 'support'),
                _buildNavItem('Admin', Icons.admin_panel_settings, 'admin'),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentSection) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'accounts':
        return _buildAccountsContent();
      case 'applications':
        return _buildApplicationsContent();
      case 'services':
        return _buildServicesContent();
      case 'support':
        return _buildSupportContent();
      case 'admin':
        return _buildAdminContent();
      default:
        return const Center(child: Text('Section not found'));
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Users',
                _dashboardStats?['totalUsers']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Active Maids',
                _dashboardStats?['activeMaids']?.toString() ?? '0',
                Icons.cleaning_services,
                Colors.green,
              ),
              _buildStatCard(
                'Pending Applications',
                _dashboardStats?['pendingApplications']?.toString() ?? '0',
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Total Services',
                _dashboardStats?['totalServices']?.toString() ?? '0',
                Icons.miscellaneous_services,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Maids'),
              Tab(text: 'Homeowners'),
            ],
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Maids Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateMaidScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Maid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildUsersList('maid'),
                    ),
                  ],
                ),
                // Homeowners Tab
                _buildUsersList('homeowner'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final status = userData['status'] as String? ?? 'pending';
            final phone = userData['phone'];
            final phoneStr = phone is int ? phone.toString() : phone is String ? phone : '';
            
            final statusColor = {
              'pending': Colors.orange,
              'approved': Colors.green,
              'rejected': Colors.red,
              'suspended': Colors.grey,
            }[status] ?? Colors.grey;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: Icon(
                    userType == 'maid' ? Icons.cleaning_services : Icons.home,
                    color: Colors.deepPurple,
                  ),
                ),
                title: Text('${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['email'] ?? ''),
                    Text(phoneStr),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String action) async {
                    switch (action) {
                      case 'edit':
                        final editData = Map<String, dynamic>.from(userData);
                        editData['id'] = userId;
                        editData['phone'] = phoneStr;
                        _showEditUserDialog(editData, userType);
                        break;
                      case 'approve':
                        await _updateUserStatus(userId, 'approved');
                        break;
                      case 'reject':
                        await _updateUserStatus(userId, 'rejected');
                        break;
                      case 'suspend':
                        await _updateUserStatus(userId, 'suspended');
                        break;
                      case 'restore':
                        await _updateUserStatus(userId, 'approved');
                        break;
                      case 'delete':
                        await _deleteUser(userId);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final List<PopupMenuItem<String>> items = [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    ];
                    
                    if (status == 'pending') {
                      items.addAll([
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Approve'),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Text('Reject'),
                        ),
                      ]);
                    } else if (status == 'approved') {
                      items.add(const PopupMenuItem(
                        value: 'suspend',
                        child: Text('Suspend'),
                      ));
                    } else if (status == 'suspended') {
                      items.add(const PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore'),
                      ));
                    }
                    
                    items.add(const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ));
                    
                    return items;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                ),
                onTap: () {
                  final viewData = Map<String, dynamic>.from(userData);
                  viewData['id'] = userId;
                  viewData['phone'] = phoneStr;
                  _showUserDetails(viewData, userType);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  void _showUserDetails(Map<String, dynamic> userData, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${userData['firstName']} ${userData['lastName']}'),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(context);
                _showEditUserDialog(userData, userType);
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', userData['email']),
              _buildDetailRow('Phone', userData['phone']),
              _buildDetailRow('Status', userData['status']?.toUpperCase()),
              if (userType == 'maid') ...[
                const Divider(),
                const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (userData['services'] as List<dynamic>? ?? [])
                      .map((service) => Chip(
                            label: Text(service.toString()),
                            backgroundColor: Colors.deepPurple.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.deepPurple),
                          ))
                      .toList(),
                ),
              ],
              if (userData['location'] != null) ...[
                const Divider(),
                const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${userData['location']['city']}, ${userData['location']['area']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> userData, String userType) {
    final firstNameController = TextEditingController(text: userData['firstName'] ?? '');
    final lastNameController = TextEditingController(text: userData['lastName'] ?? '');
    final emailController = TextEditingController(text: userData['email'] ?? '');
    final phoneController = TextEditingController(text: userData['phone'] ?? '');
    final formKey = GlobalKey<FormState>();
    final userId = userData['id'] as String;

    // Only initialize services list for maids
    List<String>? selectedServices;
    if (userType == 'maid') {
      selectedServices = List<String>.from(userData['services'] ?? []);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter first name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter last name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter email';
                      if (!value!.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter numbers only',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter phone number';
                      if (!RegExp(r'^\d+$').hasMatch(value!)) {
                        return 'Please enter only numbers';
                      }
                      return null;
                    },
                  ),
                  if (userType == 'maid' && selectedServices != null) ...[
                    const SizedBox(height: 24),
                    const Text('Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

                        final services = snapshot.data!.docs;
                        return Column(
                          children: services.map((service) {
                            final serviceData = service.data() as Map<String, dynamic>;
                            final serviceName = serviceData['name'] as String;
                            return CheckboxListTile(
                              title: Text(serviceName),
                              value: selectedServices!.contains(serviceName),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    selectedServices!.add(serviceName);
                                  } else {
                                    selectedServices!.remove(serviceName);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    final phoneText = phoneController.text.trim();
                    final phoneNumber = int.tryParse(phoneText);
                    
                    if (phoneNumber == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid phone number format')),
                      );
                      return;
                    }

                    final updatedData = {
                      'firstName': firstNameController.text.trim(),
                      'lastName': lastNameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneNumber,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    // Only add services field for maids
                    if (userType == 'maid' && selectedServices != null) {
                      updatedData['services'] = selectedServices;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update(updatedData);

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User details updated successfully'),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error updating user: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating user: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Not provided'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'maid')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data!.docs;
        if (applications.isEmpty) {
          return const Center(
            child: Text('No pending maid applications'),
          );
        }

        return ListView.builder(
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index].data() as Map<String, dynamic>;
            final applicationId = applications[index].id;
            final createdAt = (application['createdAt'] as Timestamp?)?.toDate();
            final documents = application['documents'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: documents?['profilePhotoUrl'] != null
                      ? NetworkImage(documents!['profilePhotoUrl'])
                      : null,
                  child: documents?['profilePhotoUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text('${application['firstName']} ${application['lastName']}'),
                subtitle: Text(
                  'Applied: ${createdAt != null ? DateFormat('MMM d, y').format(createdAt) : 'Date not available'}\n'
                  'Phone: ${application['phone']}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Date of Birth', application['dateOfBirth']),
                        _buildDetailRow('Gender', application['gender']),
                        _buildDetailRow('Nationality', application['nationality']),
                        _buildDetailRow('Tribe', application['tribe']),
                        _buildDetailRow('Marital Status', application['maritalStatus']),
                        _buildDetailRow('Education Level', application['educationLevel']),
                        const Divider(),
                        const Text('Documents:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (documents != null) ...[
                          if (documents['nationalIdUrl'] != null)
                            _buildDocumentLink('National ID', documents['nationalIdUrl']),
                          if (documents['policeClearanceUrl'] != null)
                            _buildDocumentLink('Police Clearance', documents['policeClearanceUrl']),
                          if (documents['lcLetterUrl'] != null)
                            _buildDocumentLink('LC Letter', documents['lcLetterUrl']),
                          if (documents['educationCertificateUrl'] != null)
                            _buildDocumentLink('Education Certificate', documents['educationCertificateUrl']),
                          if (documents['medicalReportUrl'] != null)
                            _buildDocumentLink('Medical Report', documents['medicalReportUrl']),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateUserStatus(applicationId, 'rejected'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => _updateUserStatus(applicationId, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentLink(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.attachment, size: 20),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: Text(label),
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Flexible(
                        child: Image.network(
                          url,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Failed to load image'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showServiceDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85, // Adjusted for more height
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index].data() as Map<String, dynamic>;
                  final serviceId = services[index].id;
                  final isActive = service['isActive'] ?? true;

                  return Card(
                    child: InkWell(
                      onTap: () => _showServiceDialog(serviceId: serviceId, service: service),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cleaning_services,
                              size: 40,
                              color: isActive ? Colors.deepPurple : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              service['name'] ?? '',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.black87 : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'UGX ${NumberFormat("#,###").format(service['price'] ?? 0)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: isActive ? Colors.deepPurple : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                service['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isActive ? Colors.grey[600] : Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showServiceDialog({String? serviceId, Map<String, dynamic>? service}) {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final descriptionController = TextEditingController(text: service?['description'] ?? '');
    final priceController = TextEditingController(text: (service?['price'] ?? '').toString());
    final formKey = GlobalKey<FormState>();
    bool isActive = service?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(serviceId == null ? 'Add Service' : 'Edit Service'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (UGX)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a price';
                  if (double.tryParse(value!) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) => isActive = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final serviceData = {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'price': double.parse(priceController.text),
                    'isActive': isActive,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (serviceId == null) {
                    await FirebaseFirestore.instance
                        .collection('services')
                        .add(serviceData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('services')
                        .doc(serviceId)
                        .update(serviceData);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        serviceId == null
                            ? 'Service added successfully'
                            : 'Service updated successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving service: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text(serviceId == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContent() {
    return const Center(child: Text('Support Management Coming Soon'));
  }

  Widget _buildAdminContent() {
    return const Center(child: Text('Admin Management Coming Soon'));
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: isWideScreen 
          ? null 
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
        title: Text(
          _currentSection.substring(0, 1).toUpperCase() + 
          _currentSection.substring(1),
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWideScreen ? null : _buildNavigationDrawer(),
      body: Row(
        children: [
          if (isWideScreen) 
            SizedBox(
              width: 280,
              child: _buildNavigationDrawer(),
            ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
