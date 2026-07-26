import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String titleEn;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.titleEn,
    required this.icon,
    required this.iconColor,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(titleEn, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: iconColor == AppColors.blue || iconColor == AppColors.purple
                  ? Colors.white
                  : iconColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ]
        ],
      ),
    );
  }
}
