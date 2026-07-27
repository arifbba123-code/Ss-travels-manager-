import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/admin_repository.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/app_theme.dart';

/// Super-Admin-only screen: real-time list of every admin account, plus
/// create / edit / activate-deactivate / delete actions. Backed by
/// [AdminRepository.watchAll] so a change made here appears on every
/// other admin's device immediately.
class AdminManagementScreen extends StatefulWidget {
  final AppUser actingAdmin;
  const AdminManagementScreen({super.key, required this.actingAdmin});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
      body: Stack(
        children: [
          StreamBuilder<List<AppUser>>(
            stream: AdminRepository.instance.watchAll(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              final admins = snap.data!;
              if (admins.isEmpty) {
                return const Center(
                    child: Text('No admins yet.', style: TextStyle(color: AppColors.grey)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: admins.length,
                itemBuilder: (context, i) => _adminTile(admins[i]),
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: _createAdmin,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _adminTile(AppUser admin) {
    final isSelf = admin.uid == widget.actingAdmin.uid;
    final isSuper = admin.isSuperAdmin;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuper ? AppColors.gold : AppColors.blue,
          child: Icon(isSuper ? Icons.shield : Icons.person, color: Colors.black),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(admin.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              const Text('(You)', style: TextStyle(color: AppColors.grey, fontSize: 12)),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${admin.email}\n${admin.role.label} • ${admin.active ? 'Active' : 'Deactivated'}'
            '${admin.lastLogin != null ? '\nLast login: ${DateFormat('dd MMM yyyy, hh:mm a').format(admin.lastLogin!)}' : ''}',
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ),
        isThreeLine: true,
        trailing: isSuper
            ? const Icon(Icons.lock_outline, color: AppColors.grey)
            : PopupMenuButton<String>(
                color: AppColors.panel2,
                icon: const Icon(Icons.more_vert, color: AppColors.grey),
                onSelected: (v) {
                  if (v == 'edit') _editAdmin(admin);
                  if (v == 'toggle') _toggleActive(admin);
                  if (v == 'delete') _deleteAdmin(admin);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'toggle', child: Text(admin.active ? 'Deactivate' : 'Activate')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
      ),
    );
  }

  Future<void> _createAdmin() async {
    final result = await showDialog<_AdminForm>(
      context: context,
      builder: (_) => const _AdminFormDialog(),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await AdminRepository.instance.createAdmin(
        name: result.name,
        email: result.email,
        phone: result.phone,
        password: result.password!,
        role: result.role,
        actingAdmin: widget.actingAdmin,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name} added as ${result.role.label}')),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not create admin: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editAdmin(AppUser admin) async {
    final result = await showDialog<_AdminForm>(
      context: context,
      builder: (_) => _AdminFormDialog(existing: admin),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await AdminRepository.instance.updateAdmin(
        target: admin,
        actingAdmin: widget.actingAdmin,
        name: result.name,
        phone: result.phone,
        role: result.role,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(AppUser admin) async {
    setState(() => _busy = true);
    try {
      await AdminRepository.instance
          .setActive(target: admin, actingAdmin: widget.actingAdmin, active: !admin.active);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAdmin(AppUser admin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Delete Admin', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${admin.name}\'s access to the app? This cannot be undone.',
            style: const TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await AdminRepository.instance.deleteAdmin(target: admin, actingAdmin: widget.actingAdmin);
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.red, content: Text(message)),
    );
  }
}

class _AdminForm {
  final String name, email, phone;
  final String? password;
  final UserRole role;
  _AdminForm(this.name, this.email, this.phone, this.password, this.role);
}

class _AdminFormDialog extends StatefulWidget {
  final AppUser? existing;
  const _AdminFormDialog({this.existing});

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  final _password = TextEditingController();
  late UserRole _role = widget.existing?.role ?? UserRole.admin;

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(_isEdit ? 'Edit Admin' : 'Add Admin', style: const TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_isEdit, // email/uid can't change after account creation
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Temporary Password'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: _role,
                dropdownColor: AppColors.panel2,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                  DropdownMenuItem(value: UserRole.superAdmin, child: Text('Super Admin')),
                ],
                onChanged: (r) => setState(() => _role = r ?? UserRole.admin),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _AdminForm(_name.text.trim(), _email.text.trim(), _phone.text.trim(),
                  _isEdit ? null : _password.text, _role),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
