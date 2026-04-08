import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../main.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _allTasks = [];
  List<Habit> _todayHabits = [];
  Map<int, bool> _habitStatus = {};
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Personal', 'icon': Icons.person_outline},
    {'label': 'Work', 'icon': Icons.work_outline},
    {'label': 'Study', 'icon': Icons.menu_book_outlined},
    {'label': 'Health', 'icon': Icons.favorite_outline},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tasks = await DatabaseHelper.instance.getTaskList();
    final habits = await DatabaseHelper.instance.getTodayHabits();
    final Map<int, bool> status = {};
    for (final h in habits) {
      final log = await DatabaseHelper.instance.getLogForDate(h.id!, DateTime.now());
      status[h.id!] = log?.completed == 1;
    }
    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _todayHabits = habits;
        _habitStatus = status;
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High': return Colors.red.shade400;
      case 'Medium': return Colors.orange.shade400;
      default: return Colors.green.shade400;
    }
  }

  List<Task> get _filteredTasks {
    final today = DateTime.now();
    return _allTasks.where((t) {
      final d = t.date!;
      final isToday = d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
      final isOverdue = d.isBefore(DateTime(today.year, today.month, today.day));
      if (t.status == 1) return false;
      if (!isToday && !isOverdue) return false;
      if (_selectedCategory != 'All' && t.category != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty &&
          !t.title!.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    final pendingTasks = _filteredTasks;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(updateTaskList: _loadData),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Tasks",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        OmnixApp.of(context)?.isDarkMode ?? false
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: primary,
                      ),
                      onPressed: () => OmnixApp.of(context)?.toggleTheme(),
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: primary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ).then((_) => setState(() {})),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final bool isSelected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['label']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Tasks section
            if (pendingTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.task_alt, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks today!',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...pendingTasks.map((task) => _buildTaskCard(task)),

            // Today's Habits section
            if (_todayHabits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.loop_rounded, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    "Today's Habits",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._todayHabits.map((habit) => _buildHabitRow(habit)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = _getPriorityColor(task.priority);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final isOverdue = task.date!.isBefore(DateTime(today.year, today.month, today.day));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTaskScreen(updateTaskList: _loadData, task: task),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(left: BorderSide(color: priorityColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Overdue',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(_dateFormatter.format(task.date!),
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(task.priority ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(task.category ?? 'Personal',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: task.status == 1,
                onChanged: (bool? value) {
                  task.status = (value ?? false) ? 1 : 0;
                  DatabaseHelper.instance.updateTask(task);
                  Fluttertoast.showToast(
                    msg: 'Task completed! 🎉',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  _loadData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitRow(Habit habit) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDone = _habitStatus[habit.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: isDone ? primary : Colors.grey.shade300,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.loop_rounded,
                size: 16,
                color: isDone ? primary : Colors.grey.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : null,
                    ),
                  ),
                  Text(
                    habit.category ?? 'Personal',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance
                    .toggleHabitLog(habit.id!, DateTime.now());
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? primary : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 18,
                    color: isDone ? Colors.white : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}