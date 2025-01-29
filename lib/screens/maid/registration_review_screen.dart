import 'package:flutter/material.dart';
import 'dart:io';

class RegistrationReviewScreen extends StatelessWidget {
  final Map<String, dynamic> formData;

  const RegistrationReviewScreen({super.key, required this.formData});

  Widget _buildSection(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        if (formData['biodata']['profilePhoto'] != null)
          CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(File(formData['biodata']['profilePhoto'])),
          ),
        const SizedBox(height: 16),
        _buildInfoRow('Name', '${formData['biodata']['surname']} ${formData['biodata']['lastName']}'),
        _buildInfoRow('Contact', formData['biodata']['contact']),
        _buildInfoRow('Location', formData['biodata']['locationAddress']),
      ],
    );
  }

  Widget _buildNextOfKinInfo() {
    return Column(
      children: [
        _buildInfoRow('Name', formData['nextOfKin']['name']),
        _buildInfoRow('Contact', formData['nextOfKin']['contact']),
        _buildInfoRow('Relationship', formData['nextOfKin']['relationship']),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Column(
      children: [
        _buildInfoRow('Allergies', formData['medicalRecord']['allergies']),
        _buildInfoRow('Chronic Diseases', formData['medicalRecord']['chronicDiseases']),
        _buildInfoRow('Other Medical Info', formData['medicalRecord']['otherMedicalInfo']),
      ],
    );
  }

  Widget _buildSkillsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Education', formData['skillsAndExperience']['education']),
        const SizedBox(height: 8),
        const Text('Languages:'),
        Wrap(
          spacing: 8,
          children: (formData['skillsAndExperience']['languages'] as List<String>)
              .map((language) => Chip(label: Text(language)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentsInfo() {
    return Column(
      children: [
        _buildDocumentStatus('National ID', formData['documents']['nationalId'] != null),
        _buildDocumentStatus('Medical Certificate', formData['documents']['medicalCertificate'] != null),
        _buildDocumentStatus('Police Clearance', formData['documents']['policeClearance'] != null),
        _buildDocumentStatus('Reference Letter', formData['documents']['referenceLetter'] != null),
        _buildDocumentStatus('Education Certificates', formData['documents']['educationCertificates'] != null),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildDocumentStatus(String document, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(document),
          Icon(
            isUploaded ? Icons.check_circle : Icons.error,
            color: isUploaded ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  void _submitApplication(BuildContext context) {
    // TODO: Implement submission to admin
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Submitted'),
        content: const Text(
          'Your application has been submitted for review. We will contact you once it has been verified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection('Personal Information', _buildPersonalInfo()),
            _buildSection('Next of Kin', _buildNextOfKinInfo()),
            _buildSection('Medical History', _buildMedicalInfo()),
            _buildSection('Skills & Experience', _buildSkillsInfo()),
            _buildSection('Documents', _buildDocumentsInfo()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitApplication(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
