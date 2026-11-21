import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../core/services/preferences_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String name = '', email = '', role = '';
  bool loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final prefs = PreferencesService();
    if (mounted) setState(() {
      name = prefs.getUserName() ?? 'User';
      email = prefs.getUserEmail() ?? '';
      role = prefs.getRole() ?? 'Telecaller';
      loading = false;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try { final auth = await ref.read(authServiceProvider).future; await auth.logout(); } catch (_) {}
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 16),
          CircleAvatar(radius: 52, backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(initial, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(role, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              ListTile(leading: Icon(Icons.person_outline, color: AppTheme.primaryColor), title: const Text('Name'), subtitle: Text(name)),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(leading: Icon(Icons.email_outlined, color: AppTheme.primaryColor), title: const Text('Email'), subtitle: Text(email.isNotEmpty ? email : 'N/A')),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(leading: Icon(Icons.badge_outlined, color: AppTheme.primaryColor), title: const Text('Role'), subtitle: Text(role)),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            label: const Text('Logout', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.errorColor)),
          )),
          const SizedBox(height: 16),
          Text('Prisha Pharma CRM v1.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}