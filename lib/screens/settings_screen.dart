import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helpers/database_helper.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = OmnixApp.of(context)?.isDarkMode ?? false;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 30.0),

            // Theme toggle
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: primary,
                ),
                title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                trailing: Switch(
                  value: isDark,
                  activeColor: primary,
                  onChanged: (_) => OmnixApp.of(context)?.toggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Clear all data
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear all data',
                    style: TextStyle(fontSize: 16)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Clear all data'),
                      content: const Text(
                          'Are you sure you want to clear all data? This cannot be undone.'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: const Text('Continue',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            DatabaseHelper.instance.deleteAllTasks();
                            Fluttertoast.showToast(
                              msg: 'All data cleared',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Made by credit
            Center(
              child: Column(
                children: [
                  Icon(Icons.code_rounded, color: primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Made by Abhushan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Omnix v1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}