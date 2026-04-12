import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _userEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? 'Not logged in';

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle:
                      TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle:
                      TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Update',
                      style: TextStyle(color: primary)),
              onPressed: () async {
                if (_newPasswordController.text !=
                    _confirmPasswordController.text) {
                  Fluttertoast.showToast(
                      msg: 'Passwords do not match',
                      gravity: ToastGravity.BOTTOM);
                  return;
                }
                if (_newPasswordController.text.length < 6) {
                  Fluttertoast.showToast(
                      msg: 'Password must be at least 6 characters',
                      gravity: ToastGravity.BOTTOM);
                  return;
                }
                setDialogState(() => _isChangingPassword = true);
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(
                        password: _newPasswordController.text),
                  );
                  Navigator.pop(ctx);
                  Fluttertoast.showToast(
                      msg: 'Password updated successfully!',
                      gravity: ToastGravity.BOTTOM);
                } catch (e) {
                  Fluttertoast.showToast(
                      msg: 'Failed to update password',
                      gravity: ToastGravity.BOTTOM);
                } finally {
                  setDialogState(() => _isChangingPassword = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 8),
              Text('Manage your account and data',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 24),

              // ── PROFILE SECTION ──────────────────────
              Text('Profile',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primary.withOpacity(0.15),
                      child: Text(
                        _userEmail.isNotEmpty
                            ? _userEmail[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email
                    Text(
                      _userEmail,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Verified',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade500,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),

                    // Change password button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showChangePasswordDialog(context),
                        icon: Icon(Icons.lock_outline, size: 16, color: primary),
                        label: Text('Change Password',
                            style: TextStyle(color: primary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── CLEAR DATA SECTION ───────────────────
              Text('Clear Data',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1)),
              const SizedBox(height: 12),

              _clearCard(context,
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: primary,
                  title: 'Clear Tasks',
                  subtitle: 'Delete all tasks including completed ones',
                  onTap: () => _showConfirmDialog(context,
                      title: 'Clear all tasks?',
                      content:
                          'This will permanently delete all your tasks.',
                      onConfirm: () async {
                        await DatabaseHelper.instance.deleteAllTasks();
                        Fluttertoast.showToast(
                            msg: 'All tasks cleared',
                            gravity: ToastGravity.BOTTOM);
                      })),
              const SizedBox(height: 10),

              _clearCard(context,
                  icon: Icons.loop_rounded,
                  iconColor: Colors.orange,
                  title: 'Clear Habits',
                  subtitle: 'Delete all habits and their history',
                  onTap: () => _showConfirmDialog(context,
                      title: 'Clear all habits?',
                      content:
                          'This will permanently delete all habits and streak data.',
                      onConfirm: () async {
                        await DatabaseHelper.instance.deleteAllHabits();
                        Fluttertoast.showToast(
                            msg: 'All habits cleared',
                            gravity: ToastGravity.BOTTOM);
                      })),
              const SizedBox(height: 10),

              _clearCard(context,
                  icon: Icons.book_outlined,
                  iconColor: Colors.purple,
                  title: 'Clear Journal',
                  subtitle: 'Delete all journal entries and mood data',
                  onTap: () => _showConfirmDialog(context,
                      title: 'Clear all journal entries?',
                      content:
                          'This will permanently delete all your journal entries.',
                      onConfirm: () async {
                        await DatabaseHelper.instance
                            .deleteAllJournalEntries();
                        Fluttertoast.showToast(
                            msg: 'Journal cleared',
                            gravity: ToastGravity.BOTTOM);
                      })),
              const SizedBox(height: 10),

              _clearCard(context,
                  icon: Icons.delete_sweep_rounded,
                  iconColor: Colors.red,
                  title: 'Reset Everything',
                  subtitle: 'Wipe all data from all sections',
                  onTap: () => _showConfirmDialog(context,
                      title: 'Reset all data?',
                      content:
                          'This will permanently delete ALL your tasks, habits, and journal entries.',
                      onConfirm: () async {
                        await DatabaseHelper.instance.deleteAllTasks();
                        await DatabaseHelper.instance.deleteAllHabits();
                        await DatabaseHelper.instance
                            .deleteAllJournalEntries();
                        Fluttertoast.showToast(
                            msg: 'All data reset',
                            gravity: ToastGravity.BOTTOM);
                      })),
              const SizedBox(height: 24),

              // ── ACCOUNT SECTION ──────────────────────
              Text('Account',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1)),
              const SizedBox(height: 12),

              // Logout
              GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Logout',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red)),
                            Text('Sign out of your account',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.red.shade300, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Made by credit
              Center(
                child: Column(
                  children: [
                    Icon(Icons.code_rounded, color: primary, size: 28),
                    const SizedBox(height: 6),
                    Text('Made by Abhushan',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primary)),
                    const SizedBox(height: 4),
                    Text('Omnix v1.0',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clearCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}