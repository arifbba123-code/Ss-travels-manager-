import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: const [
                CircleAvatar(radius: 30, backgroundColor: AppColors.gold, child: Icon(Icons.directions_car, color: Colors.black, size: 30)),
                SizedBox(height: 12),
                Text('SS Tours & Travels', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Manager App', style: TextStyle(color: AppColors.grey)),
                SizedBox(height: 6),
                Text('Version 1.0.0', style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tile(Icons.storage, 'Data storage', 'All data is stored offline on this device (SQLite)'),
          _tile(Icons.share, 'Reports', 'Generate PDF & PNG reports, share via WhatsApp or any app'),
          _tile(Icons.lock, 'Privacy', 'No internet connection required. Nothing leaves your device.'),
          _tile(Icons.info_outline, 'About', 'Built for fleet & daily account management'),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ),
    );
  }
}
