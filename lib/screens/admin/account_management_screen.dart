import 'package:flutter/material.dart';
import 'package:maidmatch/widgets/admin/user_details_dialog.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  String _selectedUserType = 'all';
  String _selectedStatus = 'active';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedUserType,
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All Users'),
                  ),
                  DropdownMenuItem(
                    value: 'maid',
                    child: Text('Maids'),
                  ),
                  DropdownMenuItem(
                    value: 'homeowner',
                    child: Text('Home Owners'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspended'),
                  ),
                  DropdownMenuItem(
                    value: 'banned',
                    child: Text('Banned'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 10, // TODO: Replace with actual data
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: const Text('John Doe'),
                    subtitle: Text(
                      'Maid • ${_selectedStatus.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.block),
                          onPressed: () => _showSuspendDialog(context),
                          tooltip: 'Suspend Account',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever),
                          onPressed: () => _showBanDialog(context),
                          tooltip: 'Ban Account',
                        ),
                        Switch(
                          value: _selectedStatus == 'active',
                          onChanged: (value) => _showToggleStatusDialog(context, value),
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const UserDetailsDialog(
                          userId: '123', // TODO: Pass actual user ID
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSuspendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select suspension duration:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text('1 day'),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text('1 week'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('1 month'),
                ),
              ],
              onChanged: (value) {
                // TODO: Handle duration selection
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason for suspension...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement suspension
              Navigator.pop(context);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Warning: This action is permanent and cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason for ban...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement ban
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ban Account'),
          ),
        ],
      ),
    );
  }

  void _showToggleStatusDialog(BuildContext context, bool newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus ? 'Activate' : 'Deactivate'} Account'),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Reason (optional)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement status toggle
              Navigator.pop(context);
            },
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }
}
