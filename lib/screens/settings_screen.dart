import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helpers/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
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
              Text('Manage your data',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 30),

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

              const Spacer(),

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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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