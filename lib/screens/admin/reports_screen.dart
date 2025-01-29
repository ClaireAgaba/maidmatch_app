import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedReportType,
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All Reports'),
                  ),
                  DropdownMenuItem(
                    value: 'complaints',
                    child: Text('Complaints'),
                  ),
                  DropdownMenuItem(
                    value: 'disputes',
                    child: Text('Disputes'),
                  ),
                  DropdownMenuItem(
                    value: 'abuse',
                    child: Text('Abuse'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 5, // TODO: Replace with actual data
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text('Payment Dispute'),
                    subtitle: Text(
                      'Reported by John Doe • ${DateTime.now().difference(DateTime.now().subtract(const Duration(hours: 3))).inHours}h ago',
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        _showReportDetails(context);
                      },
                      child: const Text('Take Action'),
                    ),
                    onTap: () {
                      _showReportDetails(context);
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

  void _showReportDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Report Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: const Text('High Priority'),
                    backgroundColor: Colors.red[100],
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ListTile(
                          leading: CircleAvatar(),
                          title: Text('John Doe (Home Owner)'),
                          subtitle: Text('Member since Jan 2025'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ListTile(
                          leading: CircleAvatar(),
                          title: Text('Jane Smith (Maid)'),
                          subtitle: Text('4.5★ • 12 jobs completed'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'The maid has not shown up for work for the past 3 days without any communication. I have tried calling but no response.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Take Action',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Send Warning'),
                    onPressed: () {
                      _showWarningDialog(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('Suspend Account'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuspendDialog(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('Ban User'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showBanDialog(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('Mark as Resolved'),
                    onPressed: () {
                      _showResolveDialog(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a warning message to the user:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Warning message...',
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
              // TODO: Implement warning
              Navigator.pop(context);
            },
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
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

  void _showResolveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add resolution notes:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Resolution details...',
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
              // TODO: Implement resolution
              Navigator.pop(context);
            },
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
  }
}
