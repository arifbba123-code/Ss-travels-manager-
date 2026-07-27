import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import 'admin_dashboard_screen.dart';
import 'owner_dashboard_screen.dart';

/// Single source of truth for "which dashboard does this role land on".
/// Super Admin uses the same full-access dashboard the app previously
/// called "Owner" (file/class name kept as-is to avoid an unnecessary
/// rename churn — only the on-screen label changed to "Super Admin").
Widget dashboardForRole(AppUser user) {
  switch (user.role) {
    case UserRole.superAdmin:
      return OwnerDashboardScreen(user: user);
    case UserRole.admin:
      return AdminDashboardScreen(user: user);
  }
}
