import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile header
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: AppTheme.headingMedium,
            ),
            Text(
              'john.doe@example.com',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Reports', '12'),
                _buildStatItem('Alerts', '5'),
                _buildStatItem('Saved', '3'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Menu items
            _buildMenuItem(
              icon: Icons.history,
              title: 'Report History',
              onTap: () {
                // TODO: Navigate to report history
              },
            ),
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'Notification Settings',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Saved Locations',
              onTap: () {
                // TODO: Navigate to saved locations
              },
            ),
            _buildMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help & support
              },
            ),
            _buildMenuItem(
              icon: Icons.info,
              title: 'About',
              onTap: () {
                // TODO: Navigate to about
              },
            ),
            const SizedBox(height: 24),
            
            // Logout button
            ElevatedButton(
              onPressed: () {
                // TODO: Implement logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyTextSmall,
        ),
      ],
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 